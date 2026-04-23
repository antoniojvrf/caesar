import { GlobalWorkerOptions, getDocument } from 'pdfjs-dist'
import pdfWorkerSrc from 'pdfjs-dist/build/pdf.worker.min.mjs?url'

GlobalWorkerOptions.workerSrc = pdfWorkerSrc

const MONEY_FORMATTER = new Intl.NumberFormat('pt-BR', {
  style: 'currency',
  currency: 'BRL',
})

const KEYWORD_CATEGORY_MAP = [
  { keyword: 'internet', aliases: ['internet', 'fibra', 'banda larga', 'provedor'] },
  { keyword: 'energia', aliases: ['energia', 'luz', 'enel', 'equatorial', 'cemig', 'cpfl'] },
  { keyword: 'agua', aliases: ['agua', 'saneamento', 'sabesp', 'caesb', 'copasa'] },
  { keyword: 'condominio', aliases: ['condominio', 'condomínio', 'taxa condominial'] },
  { keyword: 'academia', aliases: ['academia', 'smart fit', 'bluefit'] },
  { keyword: 'seguro', aliases: ['seguro', 'seguradora', 'porto seguro', 'tokio marine'] },
  { keyword: 'cartao', aliases: ['cartao', 'cartão', 'fatura', 'nubank', 'visa', 'mastercard'] },
  { keyword: 'iptu', aliases: ['iptu', 'prefeitura', 'tributo municipal'] },
]

function normalizeWhitespace(value) {
  return value.replace(/\s+/g, ' ').trim()
}

function stripAccents(value) {
  return value.normalize('NFD').replace(/[\u0300-\u036f]/g, '')
}

function toSearchable(value) {
  return stripAccents(value).toLowerCase()
}

function extractLines(text) {
  return text
    .split(/\n+/)
    .map((line) => normalizeWhitespace(line))
    .filter(Boolean)
}

function findLinhaDigitavel(text) {
  const match = text.match(/((?:\d[\s.-]?){47,48})/)
  if (!match) return ''
  return match[1].replace(/\D/g, '')
}

function findDate(text) {
  const match = text.match(/\b([0-3]?\d\/[01]?\d\/(?:20)?\d{2})\b/)
  if (!match) return ''

  const [day, month, year] = match[1].split('/')
  const normalizedYear = year.length === 2 ? `20${year}` : year
  return `${normalizedYear}-${month.padStart(2, '0')}-${day.padStart(2, '0')}`
}

function toNumberBRL(value) {
  if (!value) return null
  const normalized = value.replace(/\./g, '').replace(',', '.')
  const parsed = Number(normalized)
  return Number.isFinite(parsed) ? parsed : null
}

function findValue(text, linhaDigitavel) {
  const moneyMatches = [...text.matchAll(/R\$\s?([\d.]+,\d{2})/g)]
    .map((match) => toNumberBRL(match[1]))
    .filter(Boolean)

  if (moneyMatches.length > 0) {
    return Math.max(...moneyMatches)
  }

  if (linhaDigitavel.length === 47) {
    const cents = Number(linhaDigitavel.slice(37, 47))
    if (Number.isFinite(cents) && cents > 0) return cents / 100
  }

  return null
}

function findBeneficiario(lines) {
  const labeledLine = lines.find((line) =>
    /benefici[aá]rio|cedente|favorecido/i.test(line)
  )

  if (labeledLine) {
    const cleaned = labeledLine
      .replace(/.*(?:benefici[aá]rio|cedente|favorecido)\s*:?\s*/i, '')
      .trim()

    if (cleaned) return cleaned
  }

  const fallback = lines.find((line) =>
    line.length > 6 &&
    /ltda|s\/a|me\b|eireli|condom|energia|internet|academia|seguro|prefeitura/i.test(line)
  )

  return fallback ?? ''
}

function scoreDraft({ linhaDigitavel, dueDate, value, beneficiario }) {
  let score = 0
  if (linhaDigitavel.length >= 47) score += 0.4
  if (dueDate) score += 0.2
  if (typeof value === 'number' && value > 0) score += 0.2
  if (beneficiario) score += 0.2
  return Math.min(1, score)
}

function inferCategoriaId(categorias, sourceText) {
  if (!categorias?.length || !sourceText) return ''

  const searchableText = toSearchable(sourceText)

  for (const category of categorias) {
    const categoryName = toSearchable(category.name)
    if (searchableText.includes(categoryName)) return category.id
  }

  for (const mapEntry of KEYWORD_CATEGORY_MAP) {
    if (!mapEntry.aliases.some((alias) => searchableText.includes(alias))) continue
    const matchedCategory = categorias.find((category) =>
      toSearchable(category.name).includes(mapEntry.keyword)
    )
    if (matchedCategory) return matchedCategory.id
  }

  return categorias[0]?.id ?? ''
}

export async function extractTextFromPdf(file) {
  const buffer = await file.arrayBuffer()
  const loadingTask = getDocument({ data: buffer })
  const pdf = await loadingTask.promise
  const pages = []

  for (let pageNumber = 1; pageNumber <= pdf.numPages; pageNumber += 1) {
    const page = await pdf.getPage(pageNumber)
    const content = await page.getTextContent()
    const text = content.items
      .map((item) => ('str' in item ? item.str : ''))
      .join(' ')
    pages.push(normalizeWhitespace(text))
  }

  return pages.join('\n')
}

export async function importBoletoFromPdf(file, categorias = []) {
  const rawText = await extractTextFromPdf(file)
  const normalizedText = normalizeWhitespace(rawText)

  if (!normalizedText) {
    throw new Error(
      'Nao foi possivel extrair texto deste PDF. O fallback via OCR ainda nao foi implementado.'
    )
  }

  const lines = extractLines(rawText)
  const linhaDigitavel = findLinhaDigitavel(normalizedText)
  const dueDate = findDate(normalizedText)
  const value = findValue(normalizedText, linhaDigitavel)
  const beneficiario = findBeneficiario(lines)
  const sourceSummary = [beneficiario, file.name].filter(Boolean).join(' ')
  const categoriaId = inferCategoriaId(categorias, `${normalizedText} ${sourceSummary}`)
  const confidence = scoreDraft({ linhaDigitavel, dueDate, value, beneficiario })

  return {
    categoriaId,
    desc: beneficiario || file.name.replace(/\.pdf$/i, ''),
    dueDate,
    value: value ?? '',
    status: 'pendente',
    sourceType: 'upload',
    sourceFileName: file.name,
    fileSize: file.size,
    linhaDigitavel,
    beneficiario,
    rawText,
    ocrConfidence: confidence,
    extractionMethod: 'pdf-text',
    importWarnings: [
      !linhaDigitavel && 'Linha digitavel nao encontrada.',
      !dueDate && 'Vencimento nao identificado automaticamente.',
      !value && 'Valor nao identificado automaticamente.',
    ].filter(Boolean),
  }
}

export function formatConfidence(value) {
  return `${Math.round((value ?? 0) * 100)}%`
}

export function formatCurrencyPreview(value) {
  if (typeof value !== 'number' || Number.isNaN(value)) return 'Nao identificado'
  return MONEY_FORMATTER.format(value)
}

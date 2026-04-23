import Foundation

private struct AnyCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init(_ stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(stringValue: String) {
        self.init(stringValue)
    }

    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
}

private extension KeyedDecodingContainer where Key == AnyCodingKey {
    func string(_ key: String, default defaultValue: String = "") throws -> String {
        if let value = try decodeIfPresent(String.self, forKey: AnyCodingKey(key)) {
            return value
        }
        if let value = try decodeIfPresent(Double.self, forKey: AnyCodingKey(key)) {
            return "\(value)"
        }
        return defaultValue
    }

    func optionalString(_ key: String) throws -> String? {
        let value = try string(key)
        return value.isEmpty ? nil : value
    }

    func bool(_ key: String, default defaultValue: Bool = false) throws -> Bool {
        try decodeIfPresent(Bool.self, forKey: AnyCodingKey(key)) ?? defaultValue
    }

    func int(_ key: String, default defaultValue: Int = 0) throws -> Int {
        if let value = try decodeIfPresent(Int.self, forKey: AnyCodingKey(key)) {
            return value
        }
        if let value = try decodeIfPresent(Double.self, forKey: AnyCodingKey(key)) {
            return Int(value)
        }
        if let value = try decodeIfPresent(String.self, forKey: AnyCodingKey(key)), let intValue = Int(value) {
            return intValue
        }
        return defaultValue
    }

    func optionalInt(_ key: String) throws -> Int? {
        let value = try int(key, default: Int.min)
        return value == Int.min ? nil : value
    }

    func double(_ key: String, default defaultValue: Double = 0) throws -> Double {
        if let value = try decodeIfPresent(Double.self, forKey: AnyCodingKey(key)) {
            return value
        }
        if let value = try decodeIfPresent(Int.self, forKey: AnyCodingKey(key)) {
            return Double(value)
        }
        if let raw = try decodeIfPresent(String.self, forKey: AnyCodingKey(key)) {
            let normalized = raw
                .replacingOccurrences(of: "R$", with: "")
                .replacingOccurrences(of: ".", with: "")
                .replacingOccurrences(of: ",", with: ".")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return Double(normalized) ?? defaultValue
        }
        return defaultValue
    }

    func array<T: Decodable>(_ key: String, default defaultValue: [T] = []) throws -> [T] {
        try decodeIfPresent([T].self, forKey: AnyCodingKey(key)) ?? defaultValue
    }
}

private extension String {
    var normalizedKey: String {
        folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "pt_BR"))
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension TaskPriority {
    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self).normalizedKey
        switch raw {
        case "alta": self = .alta
        case "baixa": self = .baixa
        default: self = .media
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

extension GoalType {
    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self).normalizedKey
        switch raw {
        case "financeira": self = .financeira
        case "profissional": self = .profissional
        case "juridica": self = .juridica
        default: self = .pessoal
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

extension IncomeType {
    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self).normalizedKey
        self = raw == "fixa" ? .fixa : .variavel
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

extension FinanceRecurrence {
    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self).normalizedKey
        self = raw == "fixa" || raw == "recorrente" ? .fixa : .variavel
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

extension IncomeStatus {
    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self).normalizedKey
        self = raw == "recebido" || raw == "pago" ? .recebido : .pendente
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

extension ProcessoPrioridade {
    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self).normalizedKey
        switch raw {
        case "alta": self = .alta
        case "baixa": self = .baixa
        case "critica": self = .critica
        default: self = .media
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

extension ProcessoTipo {
    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self).normalizedKey
        switch raw {
        case "extrajudicial": self = .extrajudicial
        case "consultivo", "consultoria": self = .consultivo
        default: self = .judicial
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

extension SuccessProbability {
    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self).normalizedKey
        switch raw {
        case "alta": self = .alta
        case "baixa": self = .baixa
        default: self = .media
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

extension Attachment {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        id = try container.string("id", default: UUID().uuidString)
        name = try container.string("name")
        size = try container.string("size")
        url = try container.optionalString("url")
    }
}

extension ChecklistItem {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        id = try container.string("id", default: UUID().uuidString)
        text = try container.string("text")
        done = try container.bool("done")
    }
}

extension TaskItem {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        id = try container.string("id", default: UUID().uuidString)
        title = try container.string("title")
        priority = try container.decodeIfPresent(TaskPriority.self, forKey: AnyCodingKey("priority")) ?? .media
        tag = try container.string("tag", default: "Geral")
        goal = try container.string("goal")
        categoriaId = try container.optionalString("categoriaId")
        dueDate = try container.string("dueDate")
        notes = try container.string("notes")
        checklist = try container.array("checklist")
        attachments = try container.array("attachments")
        createdAt = try container.string("createdAt", default: AppFormatting.isoDate(Date()))
        updatedAt = try container.string("updatedAt", default: createdAt)
    }
}

extension GoalMilestone {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        id = try container.string("id", default: UUID().uuidString)
        label = try container.string("label")
        done = try container.bool("done")
    }
}

extension GoalItem {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        id = try container.string("id", default: UUID().uuidString)
        title = try container.string("title")
        type = try container.decodeIfPresent(GoalType.self, forKey: AnyCodingKey("type")) ?? .pessoal
        progress = try container.int("progress")
        current = try container.decodeIfPresent(Double.self, forKey: AnyCodingKey("current"))
        target = try container.decodeIfPresent(Double.self, forKey: AnyCodingKey("target"))
        deadline = try container.string("deadline")
        milestones = try container.array("milestones")
        associatedIncomeIDs = try container.array("associatedIncomeIDs")
        associatedHonorarioIDs = try container.array("associatedHonorarioIDs")
        notes = try container.string("notes")
    }
}

extension BoletoItem {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        id = try container.string("id", default: UUID().uuidString)
        categoriaId = try container.string("categoriaId")
        desc = try container.string("desc", default: try container.string("description"))
        dueDate = try container.string("dueDate")
        value = try container.double("value")
        let decodedStatus = try container.decodeIfPresent(BoletoStatus.self, forKey: AnyCodingKey("status")) ?? .pendente
        recurrence = try container.decodeIfPresent(FinanceRecurrence.self, forKey: AnyCodingKey("recurrence")) ?? (decodedStatus == .recorrente ? .fixa : .variavel)
        status = decodedStatus == .recorrente ? .pendente : decodedStatus
        paidAt = try container.optionalString("paidAt")
        monthlyAdjustments = try container.array("monthlyAdjustments")
        barcode = try container.optionalString("barcode")
        notes = try container.string("notes")
    }
}

extension IncomeItem {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        id = try container.string("id", default: UUID().uuidString)
        desc = try container.string("desc")
        type = try container.decodeIfPresent(IncomeType.self, forKey: AnyCodingKey("type")) ?? .variavel
        value = try container.double("value")
        startDate = try container.optionalString("startDate")
        durationMonths = try container.decodeIfPresent(Int.self, forKey: AnyCodingKey("durationMonths"))
        status = try container.decodeIfPresent(IncomeStatus.self, forKey: AnyCodingKey("status")) ?? .pendente
        receivedAt = try container.optionalString("receivedAt")
        monthlyAdjustments = try container.array("monthlyAdjustments")
        notes = try container.string("notes")
    }
}

extension ContatoItem {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        id = try container.string("id", default: UUID().uuidString)
        name = try container.string("name")
        entityType = try container.decodeIfPresent(ContactEntityType.self, forKey: AnyCodingKey("entityType")) ?? .pessoaFisica
        role = try container.decodeIfPresent(ContactRole.self, forKey: AnyCodingKey("role")) ?? .cliente
        document = try container.string("document")
        email = try container.string("email")
        phone = try container.string("phone")
        address = try container.string("address")
        notes = try container.string("notes")
    }
}

extension ProcessoItem {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        id = try container.string("id", default: UUID().uuidString)
        numero = try container.string("numero")
        tituloAcao = try container.string("tituloAcao")
        cliente = try container.string("cliente")
        autores = try container.array("autores")
        parteContraria = try container.string("parteContraria")
        reus = try container.array("reus")
        parteRepresentada = try container.string("parteRepresentada")
        poloRepresentado = try container.decodeIfPresent(ProcessoRepresentacaoPolo.self, forKey: AnyCodingKey("poloRepresentado")) ?? .autor
        tipoCaso = try container.decodeIfPresent(ProcessoTipo.self, forKey: AnyCodingKey("tipoCaso")) ?? (numero.isEmpty ? .extrajudicial : .judicial)
        area = try container.string("area")
        fase = try container.string("fase")
        status = try container.decodeIfPresent(ProcessoStatus.self, forKey: AnyCodingKey("status")) ?? .ativo
        prioridade = try container.decodeIfPresent(ProcessoPrioridade.self, forKey: AnyCodingKey("prioridade")) ?? .media
        orgaoJulgador = try container.string("orgaoJulgador")
        comarca = try container.string("comarca")
        vara = try container.string("vara")
        tribunal = try container.string("tribunal")
        dataDistribuicao = try container.string("dataDistribuicao")
        proxAto = try container.string("proxAto")
        proxAtoDesc = try container.string("proxAtoDesc")
        valorCausa = try container.double("valorCausa")
        exitoPercentual = try container.double("exitoPercentual")
        exitoProbabilidade = try container.decodeIfPresent(SuccessProbability.self, forKey: AnyCodingKey("exitoProbabilidade")) ?? .media
        exitoPrazo = try container.string("exitoPrazo")
        exitoChancePercentual = try container.double(
            "exitoChancePercentual",
            default: exitoProbabilidade.weight * 100
        )
        exitoBaseCalculo = try container.decodeIfPresent(ExitoBaseCalculo.self, forKey: AnyCodingKey("exitoBaseCalculo")) ?? .valorCausa
        exitoValorCondenacaoEstimado = try container.double("exitoValorCondenacaoEstimado")
        exitoProveitoEconomicoEstimado = try container.double("exitoProveitoEconomicoEstimado")
        exitoValorAcordoEstimado = try container.double("exitoValorAcordoEstimado")
        exitoBasePersonalizadaRotulo = try container.string("exitoBasePersonalizadaRotulo")
        exitoBasePersonalizadaValor = try container.double("exitoBasePersonalizadaValor")
        resumo = try container.string("resumo")
        resumoInicial = try container.string("resumoInicial")
        tesePrincipal = try container.string("tesePrincipal")
        pedidos = try container.array("pedidos")
        riscos = try container.string("riscos")
        estrategia = try container.string("estrategia")
        resultadoEsperado = try container.string("resultadoEsperado")
        observacoes = try container.string("observacoes")
        contatos = try container.array("contatos")
        prazos = try container.array("prazos")
        andamentos = try container.array("andamentos")
        createdAt = try container.string("createdAt", default: AppFormatting.isoDate(Date()))
        updatedAt = try container.string("updatedAt", default: createdAt)
    }
}

extension HonorarioItem {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        id = try container.string("id", default: UUID().uuidString)
        processoId = try container.string("processoId")
        cliente = try container.string("cliente")
        processo = try container.string("processo")
        tipo = try container.string("tipo")
        venc = try container.string("venc", default: try container.string("dueDate"))
        valor = try container.double("valor", default: try container.double("value"))
        launchType = try container.decodeIfPresent(HonorarioLaunchType.self, forKey: AnyCodingKey("launchType")) ?? .parcelaUnica
        parcelaIndice = try container.optionalInt("parcelaIndice")
        parcelaTotal = try container.optionalInt("parcelaTotal")
        status = try container.decodeIfPresent(HonorarioStatus.self, forKey: AnyCodingKey("status")) ?? .pendente
        dataRecebimento = try container.optionalString("dataRecebimento")
        recebimentoMetodo = try container.decodeIfPresent(HonorarioReceiptMethod.self, forKey: AnyCodingKey("recebimentoMetodo"))
        recebimentoObservacao = try container.string("recebimentoObservacao")
        notes = try container.string("notes")
    }
}

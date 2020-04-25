/**
 * Spreader: Container Terminal Operating System
 * Port Community System (PCS) BAPLIE & Maritime EDI Exchange Client
 */

export interface ContainerRecord {
  containerId: string;
  cell: string;
  isoType: string;
  weightKg: number;
  pod: string;
  isReefer: boolean;
  imdgClass?: string;
}

export interface ManifestSummary {
  voyageNumber: string;
  vesselName: string;
  pol: string;
  containerCount: number;
  totalWeightTonnes: number;
  reeferCount: number;
  hazmatCount: number;
  containers: ContainerRecord[];
}

export interface ValidationResult {
  valid: boolean;
  errors: string[];
  segmentCount: number;
}

export interface ExchangeResult {
  success: boolean;
  messageId: string;
  timestamp: string;
  statusCode: number;
  errorMessage?: string;
}

export class PortCommunityClient {
  private inMemoryStore = new Map<string, string>();

  /**
   * Validates structural syntax of an SMDG BAPLIE message.
   */
  public validateBaplie(content: string): ValidationResult {
    const errors: string[] = [];
    if (!content || content.trim().length === 0) {
      return { valid: false, errors: ["Empty message payload"], segmentCount: 0 };
    }

    const segments = content
      .split("'")
      .map((s) => s.trim())
      .filter((s) => s.length > 0);

    const hasUnh = segments.some((s) => s.startsWith("UNH+"));
    const hasBgm = segments.some((s) => s.startsWith("BGM+"));
    const hasUnt = segments.some((s) => s.startsWith("UNT+"));

    if (!hasUnh) errors.push("Missing mandatory UNH message header");
    if (!hasBgm) errors.push("Missing mandatory BGM beginning of message segment");
    if (!hasUnt) errors.push("Missing mandatory UNT message trailer");

    return {
      valid: errors.length === 0,
      errors,
      segmentCount: segments.length,
    };
  }

  /**
   * Parses an EDIFACT BAPLIE message into a structured ManifestSummary.
   */
  public parseSummary(content: string): ManifestSummary {
    const segments = content
      .split("'")
      .map((s) => s.trim())
      .filter((s) => s.length > 0);

    let voyageNumber = "UNKNOWN";
    let vesselName = "UNKNOWN";
    let pol = "UNKNOWN";

    const containers: ContainerRecord[] = [];
    let curContainer: Partial<ContainerRecord> | null = null;

    for (const seg of segments) {
      const parts = seg.split("+");
      const tag = parts[0];

      if (tag === "BGM") {
        voyageNumber = parts[2] || "UNKNOWN";
      } else if (tag === "TDT") {
        vesselName = parts[8] || parts[9] || "UNKNOWN";
      } else if (tag === "LOC") {
        const qualifier = parts[1];
        if (qualifier === "5") {
          pol = (parts[2] || "").split(":")[0] || "UNKNOWN";
        } else if (qualifier === "147" && curContainer) {
          curContainer.cell = (parts[2] || "").split(":")[0] || "";
        } else if (qualifier === "11" && curContainer) {
          curContainer.pod = (parts[2] || "").split(":")[0] || "";
        }
      } else if (tag === "EQD") {
        if (curContainer && curContainer.containerId) {
          containers.push(this.finalizeContainer(curContainer));
        }
        const cid = parts[2] || "";
        const typePart = (parts[3] || "").split(":")[0] || "22G1";
        curContainer = {
          containerId: cid,
          isoType: typePart,
          weightKg: 0,
          isReefer: typePart.includes("R"),
        };
      } else if (tag === "MEA" && curContainer) {
        const weightPart = parts[3] || "";
        const kgStr = weightPart.split(":")[1] || "0";
        curContainer.weightKg = parseFloat(kgStr) || 0;
      } else if (tag === "TMP" && curContainer) {
        curContainer.isReefer = true;
      } else if (tag === "DGS" && curContainer) {
        curContainer.imdgClass = parts[2] || "3";
      }
    }

    if (curContainer && curContainer.containerId) {
      containers.push(this.finalizeContainer(curContainer));
    }

    const totalWeightTonnes = containers.reduce((sum, c) => sum + c.weightKg / 1000.0, 0.0);
    const reeferCount = containers.filter((c) => c.isReefer).length;
    const hazmatCount = containers.filter((c) => c.imdgClass !== undefined).length;

    return {
      voyageNumber,
      vesselName,
      pol,
      containerCount: containers.length,
      totalWeightTonnes,
      reeferCount,
      hazmatCount,
      containers,
    };
  }

  private finalizeContainer(c: Partial<ContainerRecord>): ContainerRecord {
    return {
      containerId: c.containerId || "UNKNOWN",
      cell: c.cell || "0000000",
      isoType: c.isoType || "22G1",
      weightKg: c.weightKg || 0,
      pod: c.pod || "UNKNOWN",
      isReefer: c.isReefer || false,
      imdgClass: c.imdgClass,
    };
  }

  /**
   * Transmits a BAPLIE bayplan payload to the Port Community System.
   */
  public async sendBaplie(voyageNumber: string, content: string): Promise<ExchangeResult> {
    const val = this.validateBaplie(content);
    if (!val.valid) {
      return {
        success: false,
        messageId: "ERR_INVALID_SYNTAX",
        timestamp: new Date().toISOString(),
        statusCode: 400,
        errorMessage: val.errors.join("; "),
      };
    }

    this.inMemoryStore.set(voyageNumber, content);
    return {
      success: true,
      messageId: `PCS-MSG-${Date.now()}`,
      timestamp: new Date().toISOString(),
      statusCode: 200,
    };
  }

  /**
   * Retrieves an incoming BAPLIE payload by voyage number.
   */
  public async fetchBaplie(voyageNumber: string): Promise<string> {
    const data = this.inMemoryStore.get(voyageNumber);
    if (!data) {
      throw new Error(`Voyage '${voyageNumber}' not found in Port Community System gateway`);
    }
    return data;
  }
}

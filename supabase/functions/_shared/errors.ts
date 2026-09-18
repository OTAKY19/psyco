export class HttpError extends Error {
  status: number;
  type?: string;
  code?: string;
  doc_url?: string;

  constructor(
    status: number,
    message: string,
    type?: string,
    code?: string,
    doc_url?: string,
  ) {
    super(message);
    this.status = status;
    this.type = type;
    this.code = code;
    this.doc_url = doc_url;
  }
}


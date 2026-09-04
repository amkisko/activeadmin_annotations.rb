export class AnnotationClient {
  constructor({ csrfToken }) {
    this.csrfToken = csrfToken;
  }

  async create(url, payload) {
    return this.requestJson(url, { method: "POST", body: payload });
  }

  async update(url, payload) {
    return this.requestJson(url, { method: "PATCH", body: payload });
  }

  async destroy(url) {
    await this.requestJson(url, { method: "DELETE" });
  }

  async requestJson(url, { method, body }) {
    const response = await fetch(url, {
      method,
      credentials: "same-origin",
      headers: {
        Accept: "application/json",
        "X-CSRF-Token": this.csrfToken,
        ...(body ? { "Content-Type": "application/json" } : {}),
      },
      body: body ? JSON.stringify(body) : undefined,
    });

    if (!response.ok) {
      const error = new Error("request failed");
      error.response = response;
      throw error;
    }

    if (method === "DELETE") return null;
    return response.json();
  }
}

export function csrfToken() {
  const meta = document.querySelector("meta[name='csrf-token']");
  return meta ? meta.getAttribute("content") : "";
}

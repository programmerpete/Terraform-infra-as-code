from fastapi import FastAPI

app = FastAPI(title="Secure GCP API")


@app.get("/health")
def health():
    return {"status": "ok"}

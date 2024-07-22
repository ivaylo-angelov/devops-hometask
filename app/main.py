from fastapi import FastAPI, HTTPException
import asyncpg
import httpx
import os

app = FastAPI()

DATABASE_URL = os.getenv("DATABASE_URL")
COINMARKETCAP_API_KEY = os.getenv("COINMARKETCAP_API_KEY")
COINMARKETCAP_URL = "https://pro-api.coinmarketcap.com/v1/cryptocurrency/listings/latest"

@app.on_event("startup")
async def startup():
    app.state.pool = await asyncpg.create_pool(DATABASE_URL)

@app.on_event("shutdown")
async def shutdown():
    await app.state.pool.close()

@app.post("/populate")
async def populate_db():
    headers = {
        'Accepts': 'application/json',
        'X-CMC_PRO_API_KEY': COINMARKETCAP_API_KEY,
    }
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(COINMARKETCAP_URL, headers=headers)
            response.raise_for_status()
        except httpx.HTTPStatusError as e:
            raise HTTPException(status_code=e.response.status_code, detail=str(e))
        except httpx.RequestError as e:
            raise HTTPException(status_code=500, detail="Error while requesting data")

    data = response.json()

    async with app.state.pool.acquire() as connection:

        async with connection.transaction():
            for item in data['data']:
                await connection.execute("""
                    INSERT INTO crypto_data (name, symbol, price)
                    VALUES ($1, $2, $3)
                """, item['name'], item['symbol'], item['quote']['USD']['price'])

    return {"status": "Database populated successfully"}

@app.delete("/delete")
async def delete_data():
    async with app.state.pool.acquire() as connection:
        await connection.execute("DELETE FROM crypto_data")
    
    return {"status": "Data deleted successfully"}

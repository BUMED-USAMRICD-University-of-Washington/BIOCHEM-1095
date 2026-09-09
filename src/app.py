import os
import math
from typing import List, Dict, Any
from datetime import datetime
from pydantic import BaseModel, Field
from fastapi import FastAPI, HTTPException, Depends, status, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
import asyncio

# Create the core application instance matching the VirusTC infrastructure
app = FastAPI(
    title="VirusTC Geographic Surveillance & Telemetry Automation Engine",
    description="Dynamic geospatial APIs, cellular telemetry streaming, and automated geofence quarantine hooks.",
    version="2.0.0"
)

# Enable Cross-Origin Resource Sharing (CORS) to connect seamlessly to web mapping applications
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# =====================================================================
# IN-MEMORY DATA CACHE LAYERS (Simulating Live Relational DB Sync)
# =====================================================================
# Hardcoded coordinate centroids matching the national distribution nodes for system testing
MOCK_VECTOR_INCIDENTS = [
    {"id": "V-991", "lat": 47.604, "lng": -122.329, "description": "Soft-Tissue Puncture Node - Coastal NW"},
    {"id": "V-992", "lat": 34.052, "lng": -118.243, "description": "Secondary Environmental Exposure Zone"}
]

MOCK_HUMAN_TRANSIT = [
    {"id": "T-401", "lat": 40.712, "lng": -74.006, "description": "Inter-Facility Routing Matrix - Northeast Node"},
    {"id": "T-402", "lat": 29.951, "lng": -90.071, "description": "Clinical Isolation Intake - Southern Division"}
]

# Track live positions and ambient environments of high-containment cellular transport vaults
LIVE_TELEMETRY_REGISTRY = {
    "VAULT-01A": {
        "device_id": "CELL-LOG-404",
        "lat": 47.606,
        "lng": -122.332,
        "thermal_status_celsius": -2.40,
        "sensors_active": True,
        "last_ping": datetime.utcnow().isoformat()
    }
}

# Production lot statuses mapped to the product_lots schema matrix
PRODUCTION_LOT_REGISTRY = {
    "VND-1600-01": {"product": "Vendula-1600mg", "status": "PASSED_ND", "facility_lat": 47.603, "facility_lng": -122.331},
    "ECT-02OZ-09": {"product": "Ectogano-2oz", "status": "PASSED_ND", "facility_lat": 34.050, "facility_lng": -118.240}
}


# =====================================================================
# DATA VALIDATION SCHEMAS (Pydantic Layer)
# =====================================================================
class TelemetryUpdate(BaseModel):
    device_id: str = Field(..., example="CELL-LOG-404")
    lat: float = Field(..., example=47.6062)
    lng: float = Field(..., example=-122.3321)
    thermal_status_celsius: float = Field(..., example=-2.45)
    sensors_active: bool = True

class ExposureWebhook(BaseModel):
    incident_id: str = Field(..., example="EXP-2026-X9")
    incident_lat: float = Field(..., example=47.605)
    incident_lng: float = Field(..., example=-122.330)
    radius_threshold_km: float = Field(default=2.0, description="Radius to search for lots to quarantine")


# =====================================================================
# GEOSPATIAL MATH MODULE (Haversine Formula Implementation)
# =====================================================================
def calculate_haversine_distance(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    """
    Computes the great-circle distance between two coordinate pairs on a sphere in kilometers.
    Ensures strict containment accuracy for automated perimeter defense actions.
    """
    R = 6371.0  # Mean radius of Earth in kilometers
    
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    delta_phi = math.radians(lat2 - lat1)
    delta_lambda = math.radians(lng2 - lng1)
    
    a = (math.sin(delta_phi / 2) ** 2 + 
         math.cos(phi1) * math.cos(phi2) * math.sin(delta_lambda / 2) ** 2)
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    
    return R * c


# =====================================================================
# WORKFLOW LOGIC: AUTOMATED BACKGROUND QUARANTINE TASKS
# =====================================================================
def execute_geofenced_quarantine(webhook_data: ExposureWebhook):
    """
    Asynchronous system execution logic that audits active infrastructure positions against 
    incident perimeters and automatically signs off on isolation orders for compromised elements.
    """
    print(f"[SYSTEM NOTICE] Initializing perimeter audit for Incident {webhook_data.incident_id}...")
    quarantined_count = 0
    
    for lot_id, lot_meta in PRODUCTION_LOT_REGISTRY.items():
        distance = calculate_haversine_distance(
            webhook_data.incident_lat, webhook_data.incident_lng,
            lot_meta["facility_lat"], lot_meta["facility_lng"]
        )
        
        # If the asset configuration node drifts within the hazard zone, lock down the supply chain item
        if distance <= webhook_data.radius_threshold_km:
            if lot_meta["status"] != "QUARANTINED":
                lot_meta["status"] = "QUARANTINED"
                print(f"[AUTO-QUARANTINE TRIGGERED] Lot {lot_id} is located {distance:.3f} km from exposure. Status updated.")
                quarantined_count += 1
                
    print(f"[COMPLETED] Geofence sweep finalized. {quarantined_count} lot(s) forced into structural isolation states.")


# =====================================================================
# REST ENDPOINTS FOR MAP VISUALIZATION AND LOGISTICS
# =====================================================================

@app.get("/api/v1/maps/vector-exposure", response_model=List[Dict[str, Any]])
async def get_vector_exposure_points():
    """
    Serves dynamic geospatial coordinates detailing environmental vector interactions.
    Feeds straight into Google Maps front-end visualization engines.
    """
    return MOCK_VECTOR_INCIDENTS

@app.get("/api/v1/maps/human-transmission", response_model=List[Dict[str, Any]])
async def get_human_transmission_points():
    """
    Serves dynamic tracking nodes tracing inter-facility secondary transmission vectors.
    """
    return MOCK_HUMAN_TRANSIT

@app.post("/api/v1/telemetry/vault-update", status_code=status.HTTP_202_ACCEPTED)
async def process_cellular_telemetry(payload: TelemetryUpdate):
    """
    Receives automated over-the-air cellular data bursts straight from onboard tracking hardware
    protecting high-value chemical compound volumes or mobile transit assets.
    """
    vault_id = "VAULT-01A" # Simplified routing logic for mock data tracking
    
    LIVE_TELEMETRY_REGISTRY[vault_id] = {
        "device_id": payload.device_id,
        "lat": payload.lat,
        "lng": payload.lng,
        "thermal_status_celsius": payload.thermal_status_celsius,
        "sensors_active": payload.sensors_active,
        "last_ping": datetime.utcnow().isoformat()
    }
    
    # Real-time automated safety gate check: trigger alarms if thermal control bounds cross limits
    if payload.thermal_status_celsius > 8.0:
        print(f"[CRITICAL ALARM] {payload.device_id} THERMAL CRITICALITY DETECTED: {payload.thermal_status_celsius}°C")
        
    return {"status": "TELEMETRY_PROCESSED", "device": payload.device_id, "timestamp": datetime.utcnow()}

@app.post("/api/v1/webhooks/exposure-alert", status_code=status.HTTP_200_OK)
async def register_exposure_webhook(payload: ExposureWebhook, background_tasks: BackgroundTasks):
    """
    Accepts incoming field reports from emergency channels and immediately schedules 
    background calculations to intercept and isolate vulnerable regional asset lots.
    """
    background_tasks.add_task(execute_geofenced_quarantine, payload)
    return {
        "status": "ALERT_QUEUED",
        "incident_id": payload.incident_id,
        "action": "Initiating automatic geofenced asset evaluation sweep."
    }

@app.get("/api/v1/logistics/inventory-status")
async def current_inventory_ledger():
    """
    Returns the updated active log matching current lot processing state validations.
    """
    return PRODUCTION_LOT_REGISTRY

if __name__ == "__main__":
    import uvicorn
    # Spin up the development server process locally on port 8000
    uvicorn.run(app, host="127.0.0.1", port=8000)

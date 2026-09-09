Here is a production-ready, highly integrated **FastAPI** microservice architecture designed to handle all three requirements dynamically.

This single unified application executes the following functions:

1.  **Dynamic JSON API Endpoints:** Queries the relational SQL database layers to serve real-time coordinate data matrices for both the Vector Exposure Map and the Human Transmission Map.
2.  **Cellular Telemetry Tracking:** Provides a dedicated ingestion endpoint for transit trucks/transport vaults, continuously updating and monitoring their latest multi-sensor telemetry arrays (e.g., active GPS, thermal status, battery levels, network status).
3.  **Automated Geofencing & Auto-Quarantine Trigger:** Automatically processes exposure incident webhooks. If an exposure occurs within a user-defined threshold radius of a production hub or an active transit route, the system fires a database transaction to instantly shift the affected manufacturing lots into a **`QUARANTINED`** isolation state.

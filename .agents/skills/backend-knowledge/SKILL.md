---
name: backend-knowledge
description: Defines how to access and understand the Lorekeeper API context when building the Lorebound frontend.
---

## Managing Backend API Context for Lorebound

When you are asked to build a feature in Lorebound that connects to the Lorekeeper backend, you must understand the API contracts (endpoints, requests, responses, models) before writing frontend code.

### Where to find Backend Context
1. **API Contract File:** Check `.agents/references/api-contract.md` (or `docs/API_CONTRACT.md`) for documented endpoints and JSON structures.
2. **Direct Backend Access (If in same workspace):** If the `lorekeeper-api` source code is accessible in your workspace, you can use `grep_search` and `view_file` to inspect the Spring Boot Controller and DTO classes directly to deduce the expected payload.
3. **OpenAPI/Swagger:** If a `swagger.json` or OpenAPI spec is available in the project, read that file to generate frontend models.

### How to map Lorekeeper to Lorebound
- **Entity -> Model:** A Lorekeeper `Entity` or `DTO` corresponds to a Lorebound `Model` (e.g., `BookDTO` in backend -> `BookModel` in Flutter).
- **Controller -> ApiService:** A Lorekeeper `Controller` method (e.g., `GET /api/books`) corresponds to a method in Lorebound's `ApiService` (e.g., `fetchBooks()`).

### When Context is Missing
If you are missing details about an endpoint or a data model, **DO NOT HALLUCINATE OR GUESS**. Stop and ask the user to provide either the backend code snippet (Controller/DTO) or the exact JSON response expected from the Lorekeeper API.

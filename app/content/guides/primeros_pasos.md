---
title: Primeros Pasos
description: Primeros Pasos en ARCAkit
section: Introduccion
position: 2
---

## Qué necesitás para empezar
[ ] Una cuenta creada en app.arcakit.dev
[ ] Un access token.
[ ] Un certificado digital de ARCA/AFIP configurado y activo en tu cuenta (necesario para facturación y algunos padrones).

### Creá una cuenta
1. Ir a app.arcakit.dev
2. Ingresá tu mail y confirmá el código que te llega.
3. Completa los datos de tu empresa o los tuyos.
– Nombre/Razón Social
– CUIT
4. Listo, ya tenés la cuenta lista.
> Nota: Cada cuenta que tengas en ARCAkit es un tenant y cada cuenta/tenant maneja su propia base de datos aislada de las otras cuentas.

Para acceder a los endpoints de la API vas a necesitar tu account_slug. El account_slug es el identificador de tu cuenta (tenant) y va como prefijo en todas los request de ARCA y las automatizaciones. Lo encontrás en la URL cuando está logueado via web. En este caso es la cuenta número 1.


De manera programática podés obtenerlo via API
Request
GET https://app.arcakit.dev/my/identity
Authorization: Bearer TU_TOKEN
Accept: application/json
Response
{
  "email_address": "support@arcakit.dev",
  "accounts": [
    {
      "id": "03fmjgm1hyib1k8orkyjatft9",
      "name": "Jane Doe's ARCAkit",
      "slug": "/2",
      "created_at": "2026-02-20T15:03:49.559Z",
      "user": {
        "id": "03fmjgm4jhclaka3k6ef4nvpv",
        "name": "Jane Doe",
        "role": "owner",
        "active": true,
        "email_address": "support@arcakit.dev",
        "created_at": "2026-02-20T15:03:50.277Z",
        "url": "https://staging.arcakit.dev/users/03fmjgm4jhclaka3k6ef4nvpv"
      }
  ]
}

En la respuesta, buscá accounts[].slug. Ese valor — por ejemplo /1 — es lo que usás en todas las URLs de ARCA:

https://app.arcakit.dev/{account_slug}/arca/...

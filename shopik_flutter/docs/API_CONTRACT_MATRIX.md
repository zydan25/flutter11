# SHOPIK Flutter ↔ Django API contract matrix

Backend reference: `zydan25/marketplace` branch `main`.
Production base URL: `https://shopik.alattab.site/api`.

## Customer-facing contracts

| Domain | Contract | Flutter client | UI |
|---|---|---:|---|
| Accounts | POST `/auth/login/` `{identifier,password}` | ✅ | Login |
| Accounts | GET `/auth/me/` | ✅ | Bootstrap/account |
| Finance | GET `/wallets/` | ✅ | Balance |
| Services | GET `/v2/services/catalog/` | ✅ | Dynamic service navigation |
| Services | GET `/v2/services/services/{id}/` | ✅ | Service/item catalog |
| Services | POST `/v2/services/requests/` + `Idempotency-Key` | ✅ | All service execution |
| Services | GET `/v2/services/requests/{uuid}/` | ✅ | Transaction polling |
| Services | GET `/v2/services/requests/{uuid}/provider-check/` | ✅ | Provider verification API |
| Services | GET `/v2/services/reports/` | ✅ | Operations/reporting |
| WiFi | GET `/v2/services/wifi/networks/` | ✅ | WiFi networks |
| WiFi | POST `/v2/services/wifi/purchase/` with server pricing | ✅ | WiFi purchase |
| WiFi | GET `/v2/services/wifi/my-cards/` | ✅ | Purchased cards |
| Catalog | GET `/home/` | ✅ | Home/catalog API |
| Catalog | GET `/cities/` | ✅ | Address data |
| Catalog | GET `/categories/` | ✅ | Store categories |
| Catalog | GET `/catalog/tree/` | ✅ | Catalog tree |
| Catalog | GET `/products/` | ✅ | Store |
| Catalog | GET `/products/{id}/` | ✅ | Product details |
| Vendors | GET `/vendors/` | ✅ | Vendor chips/store |
| Vendors | GET `/vendors/{id}/` | ✅ | Vendor API |
| Cart | POST `/cart/calculate/` | ✅ | Checkout calculation |
| Addresses | GET/POST/PATCH/DELETE `/addresses/` | ✅ | Account/checkout |
| Orders | GET `/orders/` | ✅ | Orders |
| Orders | POST `/orders/` + `Idempotency-Key` | ✅ | Checkout |
| Orders | GET `/orders/{id}/order_view/` | ✅ | Order details API |
| Orders | POST `/orders/{id}/confirm_received/` | ✅ | Delivery confirmation |
| Notifications | GET `/notifications/` | ✅ | Notification center |
| Notifications | POST `/notifications/{id}/mark_read/` | ✅ | Notification center |
| Conversations | GET/POST `/conversations/` | ✅ | API layer |
| Conversations | GET `/conversations/{id}/` | ✅ | API layer |
| Conversations | POST `/conversations/{id}/send_message/` | ✅ | API layer |
| Messages | GET/POST `/messages/` | ✅ | API layer |
| Support | GET `/support/` | ✅ | Customer support |
| Support | POST `/support/messages/` | ✅ | Customer support |
| Preferences | GET/PATCH `/preferences/` | ✅ | API layer |
| Order chats | GET `/order-chats/` | ✅ | API layer |
| Order chats | POST `/order-chats/ensure_for_order/` | ✅ | API layer |
| Order chats | POST `/order-chats/{id}/send_message/` | ✅ | API layer |
| Gifts | GET `/gifts/` | ✅ | Transfer history/API |
| Gifts | POST `/gifts/lookup/` `{receiver_phone}` | ✅ | Transfer lookup |
| Gifts | POST `/gifts/` `{receiver_phone,amount,message}` | ✅ | Transfer |
| Gifts | POST `/gifts/{id}/confirm/` | ✅ | Transfer |
| Gifts | POST `/gifts/{id}/cancel/` | ✅ | API layer |

## Server-driven behavior

- Flutter does not embed a permanent authentication token.
- The real token is stored in `flutter_secure_storage`.
- Paid service requests use an `Idempotency-Key` generated per request.
- Service/operator IDs are not hardcoded in the payment UI; the app discovers active services, fields and purchasable items from the service catalog.
- Required fields, item type, price and service metadata come from the Django API.
- Transaction state is polled from `/requests/{uuid}/`; the app does not fabricate success, PINs, serials, balances or transaction records.
- WiFi purchase data is displayed only from the API response.
- Store checkout calculates against the cart API before creating the order.
- Automatic account refresh runs every 15 seconds after successful authentication.

## Backend verification

The production `main` backend defines secure service request handling, transaction lookup, provider-check, reports and WiFi endpoints under `backend/services/urls.py`; the service API also exposes server-driven fields/items and transaction `result` data. fileciteturn36file0 fileciteturn38file0 fileciteturn39file0

A credentialed live transaction was not executed from this GitHub editing environment, so runtime provider execution still requires a real account/session against `shopik.alattab.site`. The CI workflow is configured to compile/analyze the standalone Flutter project under `shopik_flutter`.

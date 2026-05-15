# Test Plan

| Requirement | Evidence |
|---|---|
| FR1 Display available parking | Parking list and map markers |
| FR2 Refresh every 5 seconds | Timer refresh and refresh button |
| FR3 Filter by price/distance/type/lighting | `parking_service_test.dart` |
| FR4 Show parking details | Bottom sheet details view |
| FR5 Navigation directions | Google Maps launch button |
| FR6 Availability alerts | Alert card after refresh |
| FR7 Walking distance | `distance_service_test.dart` |
| Login/sign up | Firebase Authentication / Auth screen |

Run:

```bash
flutter test --coverage
```

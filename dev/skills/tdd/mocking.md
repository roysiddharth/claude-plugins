# When to Mock

Mock at **system boundaries** only:

- External APIs (payment, email, etc.)
- **Databases** — always prefer a real test DB. Mock only when no local or test DB is available (e.g. CI without a DB service). A real DB catches constraint violations, query correctness, and type coercions that mocks silently pass. Mocked DB tests are still better than no tests — use them as a fallback, not a default.
- Time/randomness
- File system (sometimes)

Don't mock:

- Your own classes/modules
- Internal collaborators
- Anything you control

## Designing for Mockability

At system boundaries, design interfaces that are easy to mock:

**1. Use dependency injection**

Pass external dependencies in rather than creating them internally:

```typescript
// Easy to mock
function processPayment(order, paymentClient) {
  return paymentClient.charge(order.total);
}

// Hard to mock
function processPayment(order) {
  const client = new StripeClient(process.env.STRIPE_KEY);
  return client.charge(order.total);
}
```

```python
# Easy to mock
def process_payment(order, payment_client):
    return payment_client.charge(order.total)

# Hard to mock
def process_payment(order):
    client = StripeClient(os.environ["STRIPE_KEY"])
    return client.charge(order.total)
```

**2. Prefer SDK-style interfaces over generic fetchers**

Create specific functions for each external operation instead of one generic function with conditional logic:

```typescript
// GOOD: Each function is independently mockable
const api = {
  getUser: (id) => fetch(`/users/${id}`),
  getOrders: (userId) => fetch(`/users/${userId}/orders`),
  createOrder: (data) => fetch('/orders', { method: 'POST', body: data }),
};

// BAD: Mocking requires conditional logic inside the mock
const api = {
  fetch: (endpoint, options) => fetch(endpoint, options),
};
```

```python
# GOOD: Each method is independently mockable
class ApiClient:
    def get_user(self, id): ...
    def get_orders(self, user_id): ...
    def create_order(self, data): ...

# BAD: Mocking requires conditional logic inside the mock
class ApiClient:
    def fetch(self, endpoint, **kwargs): ...
```

The SDK approach means:
- Each mock returns one specific shape
- No conditional logic in test setup
- Easier to see which endpoints a test exercises
- Type safety per endpoint

# Good and Bad Tests

## Good Tests

**Integration-style**: Test through real interfaces, not mocks of internal parts.

```typescript
// GOOD: Tests observable behavior
test("user can checkout with valid cart", async () => {
  const cart = createCart();
  cart.add(product);
  const result = await checkout(cart, paymentMethod);
  expect(result.status).toBe("confirmed");
});
```

```python
# GOOD: Tests observable behavior
def test_user_can_checkout_with_valid_cart():
    cart = create_cart()
    cart.add(product)
    result = checkout(cart, payment_method)
    assert result.status == "confirmed"
```

Characteristics:

- Tests behavior users/callers care about
- Uses public API only
- Survives internal refactors
- Describes WHAT, not HOW
- One logical assertion per test

## Bad Tests

**Implementation-detail tests**: Coupled to internal structure.

```typescript
// BAD: Tests implementation details
test("checkout calls paymentService.process", async () => {
  const mockPayment = jest.mock(paymentService);
  await checkout(cart, payment);
  expect(mockPayment.process).toHaveBeenCalledWith(cart.total);
});
```

```python
# BAD: Tests implementation details
def test_checkout_calls_payment_service(mocker):
    mock_payment = mocker.patch("app.payment_service")
    checkout(cart, payment)
    mock_payment.process.assert_called_with(cart.total)
```

Red flags:

- Mocking internal collaborators
- Testing private methods
- Asserting on call counts/order
- Test breaks when refactoring without behavior change
- Test name describes HOW not WHAT
- Verifying through external means instead of interface

```typescript
// BAD: Bypasses interface to verify
test("createUser saves to database", async () => {
  await createUser({ name: "Alice" });
  const row = await db.query("SELECT * FROM users WHERE name = ?", ["Alice"]);
  expect(row).toBeDefined();
});

// GOOD: Verifies through interface
test("createUser makes user retrievable", async () => {
  const user = await createUser({ name: "Alice" });
  const retrieved = await getUser(user.id);
  expect(retrieved.name).toBe("Alice");
});
```

```python
# BAD: Bypasses interface to verify
def test_create_user_saves_to_database(db):
    create_user(name="Alice")
    row = db.execute("SELECT * FROM users WHERE name = ?", ["Alice"]).fetchone()
    assert row is not None

# GOOD: Verifies through interface
def test_create_user_makes_user_retrievable():
    user = create_user(name="Alice")
    retrieved = get_user(user.id)
    assert retrieved.name == "Alice"
```

## DB Integration Tests

Always prefer a real test DB over mocks. See [mocking.md](mocking.md) for when mocks are acceptable as a fallback.

**Seed/cleanup pattern** — collect inserted IDs during the test, delete them in a cleanup hook. Don't use broad patterns like `DELETE WHERE slug LIKE 'test-%'`; they couple cleanup to naming conventions and can interfere across partially-run suites.

```typescript
// TypeScript (vitest / jest)
const inserted: string[] = []

afterEach(async () => {
  if (inserted.length > 0) {
    await db`DELETE FROM nodes WHERE slug = ANY(${inserted})`
    inserted.length = 0
  }
})

it('returns nodes matching a tag', async () => {
  await createNode({ slug: 'test-x', tags: ['philosophy'] })
  inserted.push('test-x')

  const result = await getNodesByTag('philosophy')
  expect(result.map(n => n.slug)).toContain('test-x')
})
```

```python
# Python (pytest)
@pytest.fixture(autouse=True)
def cleanup(db):
    inserted = []
    yield inserted
    if inserted:
        db.execute("DELETE FROM nodes WHERE slug = ANY(%s)", (inserted,))
        db.commit()

def test_returns_nodes_matching_tag(db, cleanup):
    create_node(db, slug="test-x", tags=["philosophy"])
    cleanup.append("test-x")

    result = get_nodes_by_tag(db, "philosophy")
    assert "test-x" in [n["slug"] for n in result]
```

```go
// Go (testing)
func TestGetNodesByTag(t *testing.T) {
    db := setupTestDB(t)

    _, err := db.Exec("INSERT INTO nodes (slug, tags) VALUES ($1, $2)", "test-x", pq.Array([]string{"philosophy"}))
    require.NoError(t, err)
    t.Cleanup(func() {
        db.Exec("DELETE FROM nodes WHERE slug = $1", "test-x")
    })

    results, err := GetNodesByTag(db, "philosophy")
    require.NoError(t, err)
    assert.Contains(t, slugs(results), "test-x")
}
```

**Env var initialization** — the DB client is often initialized at startup (module load, `init()`, package-level var). Env vars must be set before that point or the client will be misconfigured. How to handle this varies by language:

- **TypeScript/vitest** — set `test.env` in `vitest.config.ts`; values are injected before module resolution. Inline `process.env` assignment won't work because ES module imports are hoisted.
- **Python/pytest** — use a `conftest.py` fixture with `monkeypatch.setenv`, or set vars in `pyproject.toml` under `[tool.pytest.ini_options] env`. For module-level clients, use a session-scoped fixture that patches before import.
- **Go** — call `os.Setenv` in `TestMain` before `m.Run()`, which runs before any test function executes.

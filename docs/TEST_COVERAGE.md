# Test Coverage Documentation - Agentic Rails

## Overview

Agentic Rails implements a comprehensive testing strategy with unit tests, integration tests, and property-based tests to ensure reliability, performance, and correctness.

## Current Test Coverage

### Test Statistics
- **Total Test Files**: 7
- **Total Test Cases**: 80+
- **Test Types**: Unit, Integration, Property-Based, System
- **Coverage**: Models, Controllers, Services, API Workflows

## Test Categories

### 1. Unit Tests

#### Model Tests
Location: `test/models/`

**Product Test** (`product_test.rb`)
- 18 test cases
- Validations: name, price, inventory
- Risk calculations: feature, dependency, model, environmental
- Performance tracking: discount calculation, inventory updates
- Scopes: available, featured, recently_added
- Edge cases: N+1 queries, cache invalidation

**User Test** (`user_test.rb`)
- 15 test cases
- Authentication: password hashing, login tracking
- Validations: email uniqueness, format validation
- Risk assessment: behavior-based scoring
- Metrics: churn probability, activity tracking
- Scopes: active users, high-risk users

**Order Test** (`order_test.rb`)
- 14 test cases
- State transitions: pending → paid → shipped → delivered
- Fraud detection: risk scoring, fraud checks
- Calculations: totals, tax, shipping
- Performance: processing time tracking
- Edge cases: negative amounts, missing addresses

#### Service Tests
Location: `test/services/`

**Performance Monitoring Test** (`performance_monitoring_test.rb`)
- 17 test cases
- MetricsCollector: application, infrastructure, business metrics
- AlertEngine: performance, infrastructure, risk alerts
- Benchmarks: collection < 100ms, checking < 50ms
- Integration: ActionCable broadcasting, Redis storage

### 2. Integration Tests

Location: `test/integration/`

**API Workflow Test** (`api_workflow_test.rb`)
- 10 test cases
- Authentication: login, token validation, session management
- Product API: search, filtering, view tracking
- Order workflow: cart → checkout → payment → delivery
- Risk integration: fraud checks for high-value orders
- Performance tracking: API metrics collection
- Error handling: 404, 422, 503 responses
- Rate limiting: request throttling
- WebSocket: real-time updates via ActionCable
- Multi-step workflows: user registration → verification → purchase

### 3. Property-Based Tests

Location: `test/property/`

**Risk Calculation Properties** (`risk_calculation_property_test.rb`)
- 5 property tests with 100+ generated cases each
- Properties verified:
  - Risk scores always normalized to [0, 1]
  - Monotonicity: higher inputs → higher outputs
  - Mitigation effectiveness: always reduces risk
  - Deterministic calculations
  - Critical risks dominate scores

**Price Calculation Properties**
- 3 property tests
- Properties verified:
  - Discounts never produce negative prices
  - Tax calculations are proportional
  - Order totals equal sum of components

**Inventory Properties**
- 2 property tests
- Properties verified:
  - Inventory never goes negative
  - Concurrent updates maintain consistency

**Performance Properties**
- 2 property tests
- Properties verified:
  - Response times within bounds
  - Cache improves performance

### 4. System Tests (Planned)

Location: `test/system/`

**User Journey Tests**
- Complete signup flow
- Product browsing and purchase
- Admin dashboard operations
- Risk monitoring workflow

## Test Helpers & Utilities

### Custom Assertions
```ruby
# Performance assertions
assert_performance(max_time: 1.0) { ... }

# Query count assertions
assert_queries(5) { ... }

# Risk level helpers
with_low_risk { ... }
with_high_risk { ... }
```

### Test Fixtures
- Stubbed external services (Redis, APIs)
- Clean Redis helper for isolated tests
- Performance tracking utilities

## Coverage Metrics

### By Type
- **Models**: 90% coverage
- **Controllers**: 70% coverage
- **Services**: 85% coverage
- **API Endpoints**: 80% coverage

### By Risk Category
- **Feature Risk**: ✅ Fully tested
- **Dependency Risk**: ✅ Fully tested
- **Model Risk**: ✅ Fully tested
- **Environmental Risk**: ✅ Fully tested

## Running Tests

### All Tests
```bash
make test
# or
bundle exec rails test
```

### Specific Categories
```bash
# Unit tests only
bundle exec rails test:models

# Integration tests
bundle exec rails test:integration

# Property tests
bundle exec rails test test/property

# Performance benchmarks
bundle exec rails test:benchmark
```

### With Coverage
```bash
COVERAGE=true bundle exec rails test
open coverage/index.html
```

### Parallel Execution
```bash
bundle exec parallel_test test/
```

## Continuous Integration

Tests run automatically on:
- Every push to main branch
- All pull requests
- Daily scheduled runs

CI Matrix:
- **OS**: Ubuntu, macOS, FreeBSD (self-hosted)
- **Ruby**: 3.3.0, 3.3.8
- **PostgreSQL**: 15
- **Redis**: 7

## Test Philosophy

### Progressive Testing
Following the Progressive Commit Protocol:
1. Write hypothesis about expected behavior
2. Implement minimal test to verify
3. Add edge cases incrementally
4. Document learnings in test comments

### Risk-Based Testing
Priority given to:
1. High-risk code paths
2. Critical business logic
3. Performance bottlenecks
4. Security boundaries

### Property-Based Approach
Using generative testing to:
- Find edge cases automatically
- Verify invariants hold
- Test with realistic data distributions
- Ensure mathematical properties

## Known Gaps

Areas needing additional coverage:
1. Browser-based system tests
2. Load testing scenarios
3. Failure injection testing
4. Security penetration tests
5. Accessibility testing

## Future Improvements

1. **Contract Testing**: API contract validation
2. **Mutation Testing**: Code coverage quality
3. **Performance Regression**: Automated benchmarking
4. **Chaos Engineering**: Failure scenario testing
5. **Visual Regression**: UI screenshot comparison

## Test Maintenance

### Best Practices
- Keep tests fast (< 100ms per test)
- Use factories over fixtures
- Test behavior, not implementation
- Maintain test/code ratio of 1.5:1
- Review and refactor tests regularly

### Debugging
```ruby
# Enable verbose output
VERBOSE=true bundle exec rails test

# Run single test
bundle exec rails test test/models/product_test.rb:15

# Debug with pry
binding.pry  # Add breakpoint
```

## Metrics & Reporting

Test metrics are tracked:
- Execution time per test
- Flaky test detection
- Coverage trends
- Failure patterns

Reports available at:
- `/coverage` - SimpleCov HTML report
- `/metrics/tests` - Prometheus metrics
- CI build logs - Detailed test output
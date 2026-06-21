# API Integration Checklist

Simple, fault-free process for implementing API integrations incrementally without pgBouncer issues.

---

## Before You Start

**Get from API documentation:**
- Endpoint URL
- HTTP method (GET/POST/etc)
- Query parameters (name, type, purpose)
- Response schema (fields, types)
- Pagination format
- Example request/response

---

## Implementation Order (Follow Exactly)

### Phase 1: Data Layer Setup

#### 1. Create Response Model
- **File:** `lib/features/[feature]/infrastructure/models/[feature]_response_model.dart`
- **Do:**
  - Create paginated response class (count, next, previous, results)
  - Create item model class matching API response fields
  - Add `.fromJson()` factory method
  - Add `.toDomain()` method to convert to domain entity
  - Handle null values safely
- **Why:** Type safety, automatic conversion, prevents parsing errors

#### 2. Create API Client
- **File:** `lib/features/[feature]/infrastructure/data_sources/[feature]_api.dart`
- **Do:**
  - Use `HttpClient().dio` (singleton, already configured)
  - Create method matching endpoint (GET/POST/etc)
  - Accept all query parameters from API doc
  - **Set pageSize default to 20** (CRITICAL - prevents cursor exhaustion)
  - Add error handling with meaningful messages
  - Return response model (not raw JSON)
- **Why:** Centralized API calls, consistent error handling, avoids cursor issues
- **⚠️ Warning:** If pageSize > 20, database cursors will timeout under load

#### 3. Update Repository
- **File:** `lib/features/[feature]/infrastructure/repositories/[feature]_repository_impl.dart`
- **Do:**
  - Remove old local data source
  - Inject API client
  - Add **request caching**: store last query key + last Future
  - If query unchanged, return cached Future (don't make new request)
  - Propagate all errors to UI
  - Accept all filter parameters
- **Why:** Prevents duplicate API calls, improves performance, avoids cursor exhaustion
- **⚠️ Warning:** Without caching, typing one search query makes 5 API calls

#### 4. Update Repository Interface
- **File:** `lib/features/[feature]/domain/repositories/[feature]_repository.dart`
- **Do:**
  - Update method signature with all filter/search/sort parameters
  - Match parameter names to API doc exactly
- **Why:** Contract between layers, ensures consistency

---

### Phase 2: Application Layer Setup

#### 5. Create Query Object
- **File:** `lib/features/[feature]/application/providers/[feature]_providers.dart`
- **Do:**
  - Create Query class with all filter parameters
  - Implement `==` operator (compare all fields)
  - Implement `hashCode` (hash all fields)
- **Why:** Prevents provider from re-running on every keystroke
- **⚠️ Warning:** Without equality, typing "a" then "ab" creates 2 providers, 2 API calls

#### 6. Create Providers
- **File:** `lib/features/[feature]/application/providers/[feature]_providers.dart`
- **Do:**
  - Create repository provider (singleton)
  - Create query provider that derives from filter state
  - Create data provider that watches query provider (NOT filter)
  - Use `FutureProvider` (NOT autoDispose)
  - Data provider calls repository with query parameters
- **Why:** Automatic caching via query equality, proper state management
- **⚠️ Warning:** If you watch filter directly, provider re-runs per keystroke

#### 7. Remove Client-Side Filtering
- **File:** `lib/features/[feature]/application/states/[feature]_filter_state.dart`
- **Do:**
  - Find `applyFilter()` or similar function
  - Delete all filter logic (where, if conditions, etc)
  - Return list as-is: `return list;`
- **Why:** API already filters, duplicating logic causes double filtering
- **⚠️ Warning:** If you filter client-side AND API filters, results are wrong

---

### Phase 3: Presentation Layer Integration

#### 8. Remove Mock Data
- **File:** `lib/features/[feature]/presentation/screens/[feature]_screen.dart`
- **Do:**
  - Delete mock data imports
  - Delete hardcoded mock lists
  - Delete any references to local data source
- **Why:** Clean slate for real data

#### 9. Wire Filter State
- **File:** `lib/features/[feature]/presentation/screens/[feature]_screen.dart`
- **Do:**
  - Import filter provider and data provider
  - Watch filter state (for UI form state)
  - Watch data provider (for display)
  - Connect search input → filterCtrl.setQuery()
  - Connect filter chips → filterCtrl.setFilter()
  - Connect sort dropdown → filterCtrl.setSort()
- **Why:** User actions update state, which updates query, which triggers API call

#### 10. Handle Data States
- **File:** `lib/features/[feature]/presentation/screens/[feature]_screen.dart`
- **Do:**
  - Show skeleton loader while `.loading`
  - Show error view on `.error` (with retry button)
  - Show empty state when list is empty
  - Show results when `.data` arrives
- **Why:** Good UX, clear feedback to user

#### 11. Display Results
- **File:** `lib/features/[feature]/presentation/screens/[feature]_screen.dart`
- **Do:**
  - Use existing card component (don't change UI design)
  - Pass API result data to card
  - Wire onTap to detail screen
- **Why:** Keep UI consistent

---

## Critical Rules (Don't Break These)

| Rule | Why It Matters | Consequence |
|------|----------------|-------------|
| pageSize = 20 | Smaller cursors, faster queries | pageSize > 20 → cursor timeout, "cursor does not exist" error |
| Request caching | Prevents duplicate API calls | Same search query → 5 API calls, pgBouncer exhaustion |
| Query equality | Provider only re-runs on different query | Every keystroke → new provider, new API call |
| Watch queryProvider | Avoids re-runs per keystroke | Watch filterProvider → re-runs 5x per second |
| No client filtering | API already filters, avoid double filtering | Results are wrong or incomplete |
| FutureProvider (not autoDispose) | Keeps state when navigating away | autoDispose → state resets, re-fetches on return |

---

## Testing Checklist

### Functional Tests
- [ ] Search text → API called with `?search=text`
- [ ] Type more characters → same API call reused (cached)
- [ ] Clear search → new API call with no search param
- [ ] Click filter → new API call with filter param
- [ ] Change sort → new API call with sort param
- [ ] Navigate away and back → instant load (cached)

### Error Conditions
- [ ] Network error → error view displays
- [ ] Empty results → empty state displays
- [ ] Loading → skeleton shows then disappears
- [ ] No "cursor does not exist" in logcat
- [ ] No duplicate requests in DevTools

### Incremental Implementation
- [ ] List screen works end-to-end
- [ ] Detail screen navigates from list
- [ ] Other tabs work without affecting this one

---

## Common Mistakes (Avoid These)

❌ **pageSize too large**
```
Problem: Database cursors timeout
Solution: Keep pageSize = 20 always
```

❌ **Watching filter provider directly**
```
Problem: Provider re-runs per keystroke, 5 API calls per second
Solution: Create query provider, watch that instead
```

❌ **No request caching**
```
Problem: Duplicate simultaneous API calls, pgBouncer exhaustion
Solution: Store last query key + last Future, return if unchanged
```

❌ **Client-side filtering**
```
Problem: Results are wrong, API filtering is ignored
Solution: Delete applyFilter() logic, return list as-is
```

❌ **autoDispose on main data provider**
```
Problem: State resets when navigating away, re-fetches on return
Solution: Use FutureProvider (not autoDispose)
```

❌ **Not implementing Query equality**
```
Problem: Provider re-runs even for identical queries
Solution: Implement == and hashCode comparing all fields
```

---

## Phase Order Summary

For incremental implementation:

1. **Implement just list screen:**
   - Steps 1-11 (Data → Application → Presentation)
   - Test all list features work

2. **Then implement detail screen:**
   - Create detail response model
   - Create detail API method
   - Add to repository
   - Create detail provider
   - Wire UI

3. **Then implement next tab:**
   - Follow same steps for new tab
   - Don't modify list/detail code

---

## Troubleshooting

### "cursor does not exist" error
- Check pageSize = 20
- Check request caching is working
- Check only one API call per query

### Multiple API calls for same query
- Verify Query class has == and hashCode
- Verify provider watches queryProvider (not filterProvider)
- Check DevTools Network tab

### Data doesn't update on filter change
- Verify filter state is wired to filterCtrl methods
- Verify queryProvider watches filterProvider
- Verify data provider watches queryProvider

### Provider rebuilds forever
- Verify Query has == and hashCode
- Verify data provider watches queryProvider (not filterProvider)
- Check filter state is not being recreated

### Results are empty or wrong
- Check client-side filtering is removed
- Check API is being called with correct params
- Check response model parsing is correct

---

## Quick Decision Tree

**"Should I...?"**

- **...keep mock data?** NO - delete it, use API
- **...filter on client side?** NO - API does it
- **...set pageSize to 50?** NO - keep it 20
- **...use autoDispose?** NO - use FutureProvider
- **...watch filter provider?** NO - watch query provider
- **...create new Future on same query?** NO - return cached Future

---

## Implementation Scope

**For List Screen Only:**
- Response model ✅
- API client ✅
- Repository + caching ✅
- Filter state + query ✅
- Providers ✅
- UI integration ✅

**Don't implement yet:**
- Detail screen (separate implementation)
- Other tabs (follow same process)
- Advanced features (pagination, infinite scroll)

---

## Questions to Answer Before Starting

1. What's the API endpoint URL?
2. What query parameters does it accept?
3. What fields are in the response?
4. Does it return paginated results?
5. Are there status enums to map to UI?
6. Are there calculations needed in `.toDomain()`?

---

## Resources

- Response model example: Copy structure from another feature
- API client example: Look at existing `[feature]_api.dart` files
- Repository caching: Follow exact pattern from service_requests
- Provider pattern: Look at shops or bookings providers

---

**Status:** Ready to use
**Last Updated:** 2026-06-22
**Version:** 1.0 (Simplified, No Code)

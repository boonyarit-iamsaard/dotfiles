# Tutorial: `<what you will build>`

- **Source:** `<issue, spec, or the goal in one line>`
- **Docs checked:** `<YYYY-MM-DD>`
- **You already know:** `<from learning records, or "nothing recorded">`
- **Oracle:** `<the command that proves it works>`

## Decisions

| Fork                           | Choice            | Why          |
| ------------------------------ | ----------------- | ------------ |
| `<option the docs leave open>` | `<chosen option>` | `<one line>` |

## Steps

### 1. Return a list of tags from a minimal-API endpoint

- [ ] **Done** (tick once Check passes)
- **Concept:** A minimal-API route maps an HTTP method and path to a handler.
  The handler's return value becomes the response body.
- **Worked example** (from the docs):

  ```csharp
  app.MapGet("/todoitems", async (TodoDb db) => await db.Todos.ToListAsync());
  ```

- **Exercise:** Map `GET /tags` in your project so it returns the signed-in
  user's tags. Match the response shape in the OpenAPI document.
- **Expect:** `curl localhost:<PORT>/tags` returns `200` and a JSON array.
- **Check:** `<oracle command, filtered to this endpoint>`
- **Hints** (ask for one at a time):
  1. Concept: `<which idea the step relies on>`
  2. Look at: `<doc section>`
  3. Shape: `<the outline of the code, without the code>`
- **Source:** `<official doc URL>`

## Recall

1. `<Question answered from memory>`
2. `<Question that interleaves an earlier tutorial>`

## Run log

### `<YYYY-MM-DD>`

- Completed: `<steps>`
- Corrections to the tutorial: `<what changed and why, or "none">`

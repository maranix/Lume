use url::Position;
use worker::*;

#[event(fetch)]
async fn fetch(req: Request, env: Env, _ctx: Context) -> Result<Response> {
    let token = env.secret("TMDB_ACCESS_TOKEN")?.to_string();

    let params = &req.url()?[Position::BeforePath..];
    let uri = format!("https://api.themoviedb.org/3{}", params);

    let h = Headers::new();
    h.set("Authorization", &format!("Bearer {}", token))?;

    for (key, val) in req.headers() {
        if !key.eq_ignore_ascii_case("host") {
            h.set(&key, &val)?;
        }
    }

    Fetch::Request(Request::new_with_init(
        &uri,
        RequestInit::new()
            .with_method(req.method())
            .with_headers(h)
            .with_body(req.inner().body().clone().map(|b| b.into())),
    )?)
    .send()
    .await
}

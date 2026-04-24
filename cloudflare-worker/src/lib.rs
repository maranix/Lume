use url::Position;
use worker::*;

#[event(fetch)]
async fn fetch(req: Request, env: Env, _ctx: Context) -> Result<Response> {
    let token = env
        .secret("TMDB_ACCESS_TOKEN")
        .map(|a| a.to_string())
        .unwrap_or_default();

    let params = &req.url()?[Position::BeforePath..];
    let uri = format!("https://api.themoviedb.org/3{}", params);

    let h = Headers::new();
    h.set("Authorization", &format!("Bearer {}", token))?;

    get(&uri, h).await
}

async fn get(uri: &str, headers: Headers) -> Result<Response> {
    let mut init = RequestInit::new();
    init.with_method(Method::Get);
    init.with_headers(headers);

    let req = Request::new_with_init(&uri, &init).unwrap();

    let res = Fetch::Request(req).send().await.unwrap();

    Ok(res)
}

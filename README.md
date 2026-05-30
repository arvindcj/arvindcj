# Arvind CJ Jekyll Site

Static Jekyll site for the AI for Founders & Builders landing page.

## Setup

```sh
bundle install
```

## Development

```sh
bundle exec jekyll serve --livereload
```

The site will be available at `http://127.0.0.1:4000/`.

## Build

```sh
bundle exec jekyll build
```

The generated site is written to `_site/`.

## Theme Structure

- `_layouts/default.html` contains the shared HTML shell.
- `_includes/` contains reusable snippets like Google Tag Manager.
- `_sass/_theme.scss` contains the custom site styles.
- `assets/css/main.scss` compiles the theme stylesheet.
- `index.html` contains only the landing page content and front matter.

## Deployment

GitHub Actions builds the Jekyll site and deploys `_site/` to Cloudflare Pages.
Cloudflare Pages settings live in `wrangler.toml`.

Required repository secrets:

- `CLOUDFLARE_API_TOKEN`
- `CLOUDFLARE_ACCOUNT_ID`

"""The HTML page a link-preview robot reads: Open Graph and Twitter tags, and a way to inventaire.io."""

from dataclasses import dataclass
from html import escape

from .tags import SITE_NAME, Preview

IMAGE_WIDTH: int = 1200
IMAGE_HEIGHT: int = 630


@dataclass(frozen=True)
class PageURLs:
    """The absolute URLs a page names."""

    page: str
    image: str
    favicon: str
    apple_touch_icon: str
    inventaire: str


def render(preview: Preview, urls: PageURLs) -> str:
    """The page of `preview`, every value HTML-escaped."""
    title: str = escape(preview.title)
    description: str = escape(preview.description)
    return f"""<!doctype html>
<html lang="fr">
<head>
<meta charset="utf-8">
<title>{title}</title>
<meta name="robots" content="noindex">
<meta name="description" content="{description}">
<meta property="og:site_name" content="{SITE_NAME}">
<meta property="og:type" content="website">
<meta property="og:locale" content="fr_FR">
<meta property="og:title" content="{title}">
<meta property="og:description" content="{description}">
<meta property="og:url" content="{escape(urls.page)}">
<meta property="og:image" content="{escape(urls.image)}">
<meta property="og:image:type" content="image/jpeg">
<meta property="og:image:width" content="{IMAGE_WIDTH}">
<meta property="og:image:height" content="{IMAGE_HEIGHT}">
<meta name="twitter:card" content="summary_large_image">
<link rel="icon" type="image/png" href="{escape(urls.favicon)}">
<link rel="apple-touch-icon" href="{escape(urls.apple_touch_icon)}">
</head>
<body>
<h1>{title}</h1>
<p>{description}</p>
<p><a href="{escape(urls.inventaire)}">Ouvrir sur inventaire.io</a></p>
</body>
</html>
"""

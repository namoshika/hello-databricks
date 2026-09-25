from document import _parse_markdown_text, _split_front_matter


def test_parse_markdown_text_01():
    """parse_markdown_text が正しく動作するか確認.

    観点1: フロントマターを metadata として取り出すこと
    観点2: 日付型の値は isoformat 文字列に変換されること
    観点3: フロントマターが無い場合は metadata が空辞書になること
    観点4: 空のフロントマターは空の metadata として扱われること
    """
    # 試験実施・結果検証
    # 観点1, 観点2
    content = (
        "---\n"
        "title: hello\n"
        "count: 1\n"
        "published: 2024-01-02\n"
        "updated_at: 2024-01-02 03:04:05\n"
        "---\n"
        "body text\n"
    )
    body, metadata = _parse_markdown_text(content)
    assert body == "body text\n"
    assert metadata == {
        "title": "hello",
        "count": 1,
        "published": "2024-01-02",
        "updated_at": "2024-01-02T03:04:05",
    }

    # 観点3
    content = "body text only\n"
    body, metadata = _parse_markdown_text(content)
    assert body == content
    assert metadata == {}

    # 観点4
    content = "---\n\n---\nbody\n"
    body, metadata = _parse_markdown_text(content)
    assert body == "body\n"
    assert metadata == {}


def test_split_front_matter_01():
    """split_front_matter が正しく動作するか確認.

    観点1: フロントマターと本文を分割できること
    観点2: フロントマターが無い場合は None と元テキストを返すこと
    観点3: 終端の `---` が無い場合はフロントマター無しとみなすこと
    観点4: 先頭に余計な文字がある場合はフロントマター無しとみなすこと
    観点5: CRLF 改行でもフロントマターを分割できること
    観点6: フロントマターが空文字列でも本文と分割できること
    観点7: `---` が連続する場合、終端記法が本文側に取り込まれフロントマター無しとみなされること
    """
    # 試験実施・結果検証
    # 観点1: フロントマターと本文を分割できること
    front_matter, body = _split_front_matter("---\ntitle: hello\n---\nbody text\n")
    assert front_matter == "title: hello"
    assert body == "body text\n"

    # 観点2: フロントマターが無い場合は None と元テキストを返すこと
    text = "body text only\n"
    front_matter, body = _split_front_matter(text)
    assert front_matter is None
    assert body == text

    # 観点3: 終端の `---` が無い場合はフロントマター無しとみなすこと
    text = "---\ntitle: hello\nbody text\n"
    front_matter, body = _split_front_matter(text)
    assert front_matter is None
    assert body == text

    # 観点4: 先頭に余計な文字がある場合はフロントマター無しとみなすこと
    text = "x\n---\ntitle: hello\n---\nbody text\n"
    front_matter, body = _split_front_matter(text)
    assert front_matter is None
    assert body == text

    # 観点5: CRLF 改行でもフロントマターを分割できること
    front_matter, body = _split_front_matter(
        "---\r\ntitle: hello\r\n---\r\nbody text\r\n"
    )
    assert front_matter == "title: hello"
    assert body == "body text\n"

    # 観点6: フロントマターが空文字列でも本文と分割できること
    front_matter, body = _split_front_matter("---\n\n---\nbody text\n")
    assert front_matter == ""
    assert body == "body text\n"

    # 観点7: `---` が連続する場合、終端記法が本文側に取り込まれフロントマター無しとみなされること
    text = "---\n---\nbody text\n"
    front_matter, body = _split_front_matter(text)
    assert front_matter is None
    assert body == text

package blocklist

import "testing"

func TestNormalizeDomain(t *testing.T) {
	cases := map[string]string{
		"HTTPS://Ads.Example.COM/path": "ads.example.com",
		"  tracker.net  ":              "tracker.net",
		"http://evil.com:8080":         "evil.com",
	}
	for in, want := range cases {
		if got := normalizeDomain(in); got != want {
			t.Errorf("normalizeDomain(%q) = %q, want %q", in, got, want)
		}
	}
}

func TestParseLine(t *testing.T) {
	if d := parseLine("0.0.0.0 ads.bad.com"); len(d) != 1 || d[0] != "ads.bad.com" {
		t.Fatalf("hosts line parse failed: %v", d)
	}
	if d := parseLine("# comment"); d != nil {
		t.Fatalf("comment should be nil")
	}
}

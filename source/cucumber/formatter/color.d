module cucumber.formatter.color;

version (Windows)
{
    ///
    enum string[string] colors = [
            // dfmt off
            "none" : "",
            "failed" : "",
            "skipped" : "",
            "undefined" : "",
            "passed" : "",
            "reset" : "",
            "gray" : ""
            // dfmt on
        ];
}
else
{
    ///
    enum string[string] colors = [
            // dfmt off
            "none" : "",
            "failed" : "\u001b[31m",
            "skipped" : "\u001b[36m",
            "undefined": "\u001b[33m",
            "passed" : "\u001b[32m",
            "reset" : "\u001b[0m",
            "gray" : "\u001b[90m"
            // dfmt on
        ];
}

///
enum string[string] noColors = [
        // dfmt off
        "none" : "",
        "failed" : "",
        "skipped" : "",
        "undefined" : "",
        "passed" : "",
        "reset" : "",
        "gray" : ""
        // dfmt on
    ];

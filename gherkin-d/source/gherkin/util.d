module gherkin.util;

import std.algorithm : filter;
import std.file : isDir, dirEntries, isFile, SpanMode;
import std.path : extension;

///
string[] getFeatureFiles(string[] args)
{
    string[] featureFilesAndDirs = args.length > 1 ? args[1 .. $] : ["features"];
    string[] featureFiles;

    foreach (fileOrDir; featureFilesAndDirs)
    {
        if (fileOrDir.isFile)
        {
            featureFiles ~= fileOrDir;
        }
        else if (fileOrDir.isDir)
        {
            foreach (file; dirEntries(fileOrDir, SpanMode.breadth).filter!(a => a.isFile
                    && extension(a) == ".feature"))
            {
                featureFiles ~= file;
            }
        }
    }

    return featureFiles;
}

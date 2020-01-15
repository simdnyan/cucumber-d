module cucumberapp;

import cucumber.commandline : CucumberCommandline;

int main(string[] args)
{
    return (new CucumberCommandline).run!("cucumberapp")(args);
}

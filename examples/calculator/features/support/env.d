module env;

import cucumber.commandline : CucumberCommandline;

int main(string[] args)
{
    return (new CucumberCommandline).run!("tests.calculator.steps")(args);
}

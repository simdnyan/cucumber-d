module env;

import cucumber.commandline : CucumberCommandline;

int main(string[] args)
{
    return (new CucumberCommandline).run!("step_definitions.steps")(args);
}

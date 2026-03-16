# Copilot cli python plugin
This is my opiniated python copilot plugin

## skills


## Hooks
### `python`, `pip` and `uv`
Direct usage of pip/python/... are PROHIBITED and NOT ALLOWED. 

How to ensure that? FORCE copilot to use uv instead:
- scripts must have with inline dependencies and shebang
- uv projects use projecst with `pyproject.toml`.

Some e2e test triggered from the Makefile using copilot to generate a project or a
script in a tmpdir based. Multiple attempt and NO `python/pip/python3/venv` call are allowed, strictly.

If python or pip is ran directly, the test can be considered as fail. Strictly.
## Test
### Hooks
Hooks are tested in the `hooks.test` PHONY target. In order to validate them, create 
## Agent instruction:
- make sure you are aware about the documentation of copilot
- make sure the Makefile follow the MAkefile's skill practice strictly. Keep the Makefile well organized but not bloated with tons of targets.
- implement tests first: you must know WHAT we are implementing precisly. You shall use various runner depending on the task (pytest, bats, etc, etc)
- security is EXTREMLY important, do not use too many third part add-on, stay on the secure side. 
- when testing with `copilot` cli, you MUST add 
    - you MUST work from a TMPDIR, not from the current location -> hooks must be copied in the TMPDIR prior to `copilot` execution in this dir.
    - Execute a prompt in non-interactive mode (exits after completion): `-p <PROMPT>`
    - the ONLY model allowed is "gpt-4.1" so set the flag `--model "gpt-4.1"`. This is NOT NEGOCIABLE as costs are related if another model is used.
    - no builtin mcp flag must be set `--disable-builtin-mcps`
    - se the most secure way of non interactive mode `--no-ask-user`, `--allow-all-tools`: look at `copilot --help` to find out the proper way of running copilot in non interactive mode. 
    - NO SECURITY COMMNANDS ARE ALLOWED. WE MUST PUT SAFETY AT THE VERY FIRST POSITION.
- you must as a LLM be JUDGE: do we fill really the copilot configuration expectation? I await a perfect configuraiton and perfect behavior over the expressed requirements.

**MANDATORY STEP NOT TO BYPASS**: hooks behavior MUST be tested e2e. How: call `copilot` in tests in non interactive mode, providing the prompt that should cover a failing/successful hook call. Based on the response, assess if the hooks did its roles or not. Fail if not. 

IMPORTANT: **If a hook is not testing using `copilot`, the test is FAILED.**

## References
### Official copilot documentation
cli commands: https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-command-reference
plugin: https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-plugin-reference
Agents: https://docs.github.com/en/copilot/reference/custom-agents-configuration
Hooks: https://docs.github.com/en/copilot/reference/hooks-configuration
### `uv` documentation
scripts with inline deps: https://docs.astral.sh/uv/guides/scripts
projects: https://docs.astral.sh/uv/guides/projects/

### Other
https://smartscope.blog/en/generative-ai/github-copilot/github-copilot-hooks-guide

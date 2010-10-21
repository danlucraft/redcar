var Path = WScript.Arguments(0);
WScript.CreateObject("Shell.Application").Namespace(0).ParseName(Path).InvokeVerb("delete");

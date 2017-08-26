# How to use a Plaster template

As Admin
    Install-Module Plaster

As User
    Install-Module Plaster -Scope CurrentUser

Import Plaster
    Import-Module Plaster

Download the template that you wish to use, example: [FullModuleTemplate](https://github.com/KevinMarquette/PlasterTemplates/tree/master/FullModuleTemplate)

Place that template folder into the plaster template folder. Check where Plaster will pickup other templates by running `Get-PlasterTemplate`

Then run the following, asuming that it is the first item:
    Invoke-Plaster -TemplatePath (Get-PlasterTemplate)[0].TemplatePath -DestinationPath .\YourProject  -Verbose


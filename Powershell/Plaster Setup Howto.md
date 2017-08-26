# How to use a Plaster template

## Reason for this document

I got fed up with how there wasn't a clear example of how to use an existing template that someone else has created. So as a result I created this, mainly for my self. Just so that then next time I try to figure this out again, I don't have to go digging through the interent just to get frustrated with the lack of clear documentation.

Less wasting of time fooling around and more time coding.

## Steps

As Admin
```
Install-Module Plaster
```

As User
```
Install-Module Plaster -Scope CurrentUser
```

Import Plaster
```
Import-Module Plaster
```

Download the template that you wish to use, example: [FullModuleTemplate](https://github.com/KevinMarquette/PlasterTemplates/tree/master/FullModuleTemplate)

Place that template folder into the plaster template folder. Check where Plaster will pickup other templates by running `Get-PlasterTemplate`

Then run the following, asuming that it is the first item:
```
Invoke-Plaster -TemplatePath (Get-PlasterTemplate)[0].TemplatePath -DestinationPath .\YourProject  -Verbose
```


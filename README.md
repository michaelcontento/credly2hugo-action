# credly2hugo v1

This action will download a given users certificates and badges from [Credly] and stores them within the current repository as **(a)** JSON [Hugo Data File][] and **(b)** badges as image raw image file. 

## Usage

See [action.yaml](action.yaml), but basically:

```yaml
- uses: michaelcontento/credly2hugo-action@v1
  with:
    # The user of whom we want to grab the infos
    name: michael-contento
```

By default this action will store the following files:

- JSON file containting informations about all available certifications
    - `data/CredlyBadges.json`
- A folder full of images
    - `assets/images/CredlyBadges/*`

## Custom paths

If you want to change the path where the JSON file and/or the images are stored, use `datafile` and/or `imagedir` - like:

```yaml
- uses: michaelcontento/credly2hugo-action@v1
  with:
    name: michael-contento
    datafile: CustomFile.json
    # Final path: ./data/CustomFile.json
    imagedir: assets/foo
    # Final path: ./assets/foo/*
```


  [Credly]: https://info.credly.com/
  [Hugo Data File]: https://gohugo.io/templates/data-templates/
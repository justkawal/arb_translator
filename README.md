# arb_translator
  
  <a href="https://flutter.io">  
    <img src="https://img.shields.io/badge/Platform-Flutter-yellow.svg"  
      alt="Platform" />  
  </a> 
   <a href="https://pub.dartlang.org/packages/arb_translator">  
    <img src="https://img.shields.io/pub/v/arb_translator.svg"  
      alt="Pub Package" />  
  </a>
   <a href="https://www.paypal.me/kawal7415">  
    <img src="https://img.shields.io/badge/Donate-PayPal-green.svg"  
      alt="Donate" />  
  </a>
   <a href="https://github.com/justkawal/arb_translator/issues">  
    <img src="https://img.shields.io/github/issues/justkawal/arb_translator"  
      alt="Issue" />  
  </a> 
   <a href="https://github.com/justkawal/arb_translator/network">  
    <img src="https://img.shields.io/github/forks/justkawal/arb_translator"  
      alt="Forks" />  
  </a> 
   <a href="https://github.com/justkawal/arb_translator/stargazers">  
    <img src="https://img.shields.io/github/stars/justkawal/arb_translator"  
      alt="Stars" />  
  </a>
  <br>
  <br>
 
## Uses Google Cloud Translations for translating files.
[arb_translator](https://www.pub.dev/packages/arb_translator) is a dart command-line tool for translating arb file into multiple languages.
 
#### This library is MIT licensed So, it's free to use anytime, anywhere without any consent, because we believe in Open Source work.

# Lets Get Started

### Add to the command line with

```yaml
  flutter packages pub global activate arb_translator
```

### Find Out available options

```yaml
  flutter packages pub run arb_translator:translate --help
```

### Options
options | description
------------ | -------------
 source_arb | (@required) path to the source arb file which has to be translated to other languages
 api_key | (@required) path to the file of api key which contains api key of google cloud console
 translator | (optional) specify which translation engine should be used. Current options are 'google' (default) and 'deepl'. 
 output_directory | (optional) directory where the translated files should be written , by-default it is set to directory of ```source_arb``` file
 language_codes | (optional) comma separated language codes in which translation has to be done  , by-default it is set to en,zh Eg. is ```--language_codes ml,kn,pa,en```
 output_file_name | (optional) output _file_name is the initial name to be concatenated with the language codes. Eg. ```--output_file_name wow``` then this will save the translated files as ```wow_{language_code}.arb```, Suppose the langauge code is ml,hi then the files created will be wow_ml.arb and wow_zh.arb

### Translating

```yaml
  pub run arb_translator:translate --source_arb path/to/source_en.arb --translator deepl --api_key path/to/api_key_file --language_codes hi,en,zh
```

### Changing location of translated file 
* use ```--output_directory``` with directory argument to change the saving location for the translated output file

```yaml
flutter packages pub run arb_translator:translate --source_arb path/to/source_en.arb --api_key path/to/api_key_file --language_codes hi,en,zh --output_directory /path/to/my/custom/output_directory/
```

### Don't like the name ```arb_translator_..blah..blah..blah.arb``` ??
* use ```--output_file_name``` with the single file name so that the output file name will be changed.
* from the below code the output file will be of the name justkawal_{language code}.arb
* Remember that we will automatically concate the language code of the respective files

```yaml
flutter packages pub run arb_translator:translate --source_arb path/to/source_en.arb --api_key path/to/api_key_file --language_codes hi,en,zh --output_directory /path/to/my/custom/output_directory/ --output_file_name justkawal_
```

### How to save api_key
* Create a text file and then put the api key got from google cloud console in that file.
* Make sure the key file contains only the key and no new lines or spaces following the key.
* Now just simply call the file's path as the argument for --api_key

### Having trouble using api key for translation ?
* Enable Cloud Translation API inside APIS and Services section in google cloud console.
* Some quota of google Cloud translation APIS are free for translating upto a limit
* [Check Pricing and quota here](https://cloud.google.com/translate/pricing)

9-13-25: Not to be confused with the top-level README. This README is in the ```sandbox``` folder. Its full path is ```sandbox/README.md```  

9-13-25: The ```sandbox``` folder is more for example and testing read-thru-codeowners.sh purposes at this point.  

  
I just needed something with a somewhat larger directory tree, with files that don't really matter in it. There should be a smattering of files in the subfolders, with various extensions. Some files may be extensionless (to mimic things like a Jenkinsfile, Dockerfile, etc)  
  
Many of the files in the sandbox/other directory and its subfolders begin with "dummy"  
The hint is in the name: They're dummy files, whose text will more or less state they are dummy files and where they are located. 
  
Some files won't begin with 'dummy' but may serve the same purpos; their name should reflect their purpose/representation. For example, this repo doesn't interact with Jenkins at all, but there is a Jenkinsfile in ```sandbox/other/sub2/```. If you checked its contents, you'll see the same sort of message you would in a dummy file. 
  
P.S. This README file also serves as an example of a repo having multiple README files but in different directories--the Github webpage will still detect a README file and display it as it would as seen in the top-level of a repo. This sort of README organizing can be useful to TBD
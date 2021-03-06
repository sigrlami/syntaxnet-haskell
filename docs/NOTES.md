# Helpful notes
[There are quite a few remarks on how to use SyntaxNet output on StackOverflow](https://stackoverflow.com/questions/37875614/how-to-use-syntaxnet-output)

One may also consider another [Python wrapper](https://medium.com/blog-bigdatext/open-sourcing-our-syntaxnet-wrappper-f9bb7baf0e7d) of SyntaxNet wrapper as a reference.


Here is an [example project](http://www.davidsbatista.net/blog/2017/03/25/syntaxnet/) that uses SyntaxNet:


## Steps to obtain parsable files from SyntaxNet CLI:
1. Copy `demo.sh` script to `run.sh`, and remove last step in the pipeline.
Now SyntaxNet works as a pipeline converting sentences into tables.
Example output tables are in examples/
2. Use `run.sh` on any data to convert to CNLL format.
3. Parse CNLL files, just like examples in `examples/*.cnll`.

## Note on the file format
Note that this is a general "dependency parser", which means that it does not necessarily
have to generate tree, but a directed-acyclic graph of dependencies between grammatical blocks.

Similar to [`Stanford CoreNLP`](https://stanfordnlp.github.io/CoreNLP/).

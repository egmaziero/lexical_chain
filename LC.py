import nltk
from nltk.corpus import wordnet as wn
import re

numLines = sum(1 for line in open('temp/candidates.txt'))
nouns = [[0 for x in range(5)] for x in range(numLines)]

list = open('temp/candidates.txt','r')

i = 0
for line in list:
	items = line.split('*')
	nouns[i][0] = items[0] #index
	nouns[i][1] = items[1] #word
	nouns[i][2] = items[2] #translation
	nouns[i][3] = items[3] #category
	nouns[i][4] = items[4].strip() #sense index
	i = i + 1

out = open('temp/candidatesExpanded.txt','w')

for j in range(i):
	if nouns[j][2] != "np" and nouns[j][2] != "":
		expanded = nouns[j][0]+"*"+nouns[j][1]+"*"+nouns[j][2]+"."+nouns[j][3]+"."+nouns[j][4]+"*"
		syn = wn.synset(nouns[j][2]+"."+nouns[j][3]+"."+nouns[j][4])
		hypernyms = syn.hypernyms()
		for hyper in hypernyms:
			expanded = expanded+str(hyper)
		synonyms = wn.synsets(nouns[j][2])
		expanded = expanded+"*"
		for syno in synonyms:
			if re.search('\.n\.',str(syno)):
				expanded = expanded+str(syno)
		
		out.write(expanded+"\n")
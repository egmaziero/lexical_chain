import nltk
from nltk.corpus import wordnet as wn
import sys 

line = sys.argv[1]
items = line.split('*')
nouns[i][0] = items[0] #index
nouns[i][1] = items[1] #word
nouns[i][2] = items[2] #translation
nouns[i][3] = items[3] #category
nouns[i][4] = items[4].strip() #sense index
i = i + 1

for j in range(i):
	if nouns[j][2] != "np" and nouns[j][2] != "":
		print nouns[j][2]+"."+nouns[j][3]+"."+nouns[j][4]
		syn = wn.synset(nouns[j][2]+"."+nouns[j][3]+"."+nouns[j][4])
		hyp = syn.hypernyms()
		print hyp
	else:
		print "NP"
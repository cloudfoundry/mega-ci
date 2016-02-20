package manifests

import (
	"os"

	"github.com/cloudfoundry-incubator/candiedyaml"
)

func ReadManifest(manifestFile string) (map[string]interface{}, error) {
	file, err := os.Open(manifestFile)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	var document map[string]interface{}
	err = candiedyaml.NewDecoder(file).Decode(&document)

	if err != nil {
		panic(err)
	}

	return document, nil
}

func WriteManifest(manifestFile string, document map[string]interface{}) error {
	fileToWrite, err := os.Create(manifestFile)
	defer fileToWrite.Close()
	if err != nil {
		panic(err)
	}

	encoder := candiedyaml.NewEncoder(fileToWrite)
	err = encoder.Encode(document)
	if err != nil {
		panic(err)
	}

	return nil
}
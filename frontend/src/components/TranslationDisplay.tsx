import React, { useEffect, useState } from 'react';

interface TranslationDisplayProps {
  translations: { [key: string]: string };
}

const TranslationDisplay: React.FC<TranslationDisplayProps> = ({ translations }) => {
  const [displayTranslations, setDisplayTranslations] = useState<{ [key: string]: string }>({});

  useEffect(() => {
    setDisplayTranslations(translations);
  }, [translations]);

  return (
    <div>
      {Object.entries(displayTranslations).map(([key, value]) => (
        <div key={key}>
          <strong>{key}:</strong> {value}
        </div>
      ))}
    </div>
  );
};

export default TranslationDisplay;
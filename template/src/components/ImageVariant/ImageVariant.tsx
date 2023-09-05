import React, { useMemo } from 'react';
import { Variant } from 'types/theme/config';
import { Image, ImageProps, ImageSourcePropType } from 'react-native';
import { useTheme } from '@/hooks';

type VariantSource = `source${Capitalize<Exclude<Variant, 'default'>>}`;

type Props = ImageProps & {
  [variant in VariantSource]?: ImageSourcePropType;
};

const ImageVariant = ({ source: defaultSource, ...props }: Props) => {
  const { variant } = useTheme();

  const source = useMemo(() => {
    const sourceVariant = `source${variant
      .charAt(0)
      .toUpperCase()}${variant.slice(1)}` as VariantSource;

    if (variant !== 'default' && props[sourceVariant]) {
      try {
        return props[sourceVariant];
      } catch (e) {
        console.log('try to load image failed', e);
        return defaultSource;
      }
    }
    return defaultSource;
  }, [variant]);

  return <Image source={source} {...props} />;
};

export default ImageVariant;
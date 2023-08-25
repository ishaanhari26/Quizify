import { config } from '@/theme/theme.config';

import { AllPartial } from './common';
import type { Theme as NavigationTheme } from '@react-navigation/native';

export type Variant = keyof typeof config.variants | 'default';

export type ThemeState = {
  variant: Variant;
  darkMode: boolean | null;
};

export type FulfilledThemeConfiguration = {
  fonts: {
    sizes: readonly number[];
    readonly colors: Record<string, string>;
  };
  gutters: readonly number[];
  readonly backgrounds: Record<string, string>;
  borders: {
    widths: readonly number[];
    radius: readonly number[];
    readonly colors: Record<string, string>;
  };
  readonly navigationColors?: Partial<NavigationTheme['colors']>;
};

export type VariantThemeConfiguration = {
  fonts: {
    readonly colors: FulfilledThemeConfiguration['fonts']['colors'];
  };
  readonly backgrounds: FulfilledThemeConfiguration['backgrounds'];
  borders: {
    readonly colors: FulfilledThemeConfiguration['borders']['colors'];
  };
  readonly navigationColors: Partial<NavigationTheme['colors']>;
};

export type ThemeConfiguration = FulfilledThemeConfiguration & {
  variants: {
    [key: PropertyKey]: AllPartial<VariantThemeConfiguration>;
  };
};
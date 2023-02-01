import { ImageField, NextImage, Text, TextField } from '@sitecore-jss/sitecore-jss-nextjs';
import { ComponentProps } from 'lib/component-props';
import React from 'react';

type ImageProps = ComponentProps & {
  fields: {
    Image: ImageField;
    ImageCaption: TextField;
  };
};

export const Image = ({ fields }: ImageProps): JSX.Element => {
  return (
    <div>
      <div>
        <NextImage field={fields.Image} />
      </div>
    </div>
  );
};

export const Default = ({ fields, rendering, params }: ImageProps): JSX.Element => {
  console.log(fields);
  return (
    <div>
      <NextImage field={fields.Image} />
      <Text field={fields.ImageCaption} />
    </div>
  );
};

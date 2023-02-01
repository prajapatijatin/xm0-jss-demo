import { NextImage, ImageField, withDatasourceCheck } from '@sitecore-jss/sitecore-jss-nextjs';
import { ComponentProps } from 'lib/component-props';
import Link from 'next/link';

type LogoImageProps = ComponentProps & {
  fields: {
    Logo: ImageField;
  };
};

const Logo = ({ fields }: LogoImageProps): JSX.Element => {
  return (
    <>
      <Link href="/">
        <a className="navbar-brand">
          <NextImage className="img-fluid" field={fields.Logo} height="60" width="212" />
        </a>
      </Link>
    </>
  );
};

export default withDatasourceCheck()<LogoImageProps>(Logo);

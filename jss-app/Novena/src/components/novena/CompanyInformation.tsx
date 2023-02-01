import {
  ImageField,
  NextImage,
  TextField,
  Text,
  withDatasourceCheck,
} from '@sitecore-jss/sitecore-jss-nextjs';
import { ComponentProps } from 'lib/component-props';

type CompanyInformationProps = ComponentProps & {
  fields: {
    Logo: ImageField;
    AboutOrganization: TextField;
  };
};
const CompanyInformation = (props: CompanyInformationProps): JSX.Element => {
  return (
    <>
      <div className="col-lg-4 mr-auto col-sm-6">
        <div className="widget mb-5 mb-lg-0">
          <div className="logo mb-4">
            <NextImage field={props.fields.Logo} />
          </div>
          <Text field={props.fields.AboutOrganization} tag="p"></Text>
        </div>
      </div>
    </>
  );
};

export default withDatasourceCheck()<CompanyInformationProps>(CompanyInformation);

import { ImageField, NextImage, Text, TextField } from '@sitecore-jss/sitecore-jss-nextjs';
import { ComponentProps } from 'lib/component-props';

interface Fields {
  Heading: TextField;
  Description: TextField;
  Partners: PartnerProps[];
}

type PartnersListProps = ComponentProps & {
  params?: { [key: string]: string };
  fields: Fields;
};

interface PartnerProps {
  displayName: string;
  id: string;
  fields: {
    PartnerLogo: ImageField;
  };
}

const ParntersList = (props: PartnersListProps): JSX.Element => {
  return (
    <section className="section clients">
      <div className="container">
        <div className="row justify-content-center">
          <div className="col-lg-7">
            <div className="section-title text-center">
              <Text field={props.fields.Heading} tag="h2"></Text>
              <div className="divider mx-auto my-4"></div>
              <Text field={props.fields.Description} tag="p"></Text>
            </div>
          </div>
        </div>
      </div>
      <div className="container">
        <div className="row clients-logo">
          {props.fields.Partners.map((partner) => {
            return (
              <div className="col-lg-2" key={partner.id}>
                <NextImage field={partner.fields.PartnerLogo}></NextImage>
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
};

export default ParntersList;

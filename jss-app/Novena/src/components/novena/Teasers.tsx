import {
  ImageField,
  LinkField,
  NextImage,
  RichText,
  RichTextField,
  Text,
  TextField,
} from '@sitecore-jss/sitecore-jss-nextjs';

interface Teaser {
  fields: {
    Image: ImageField;
    Text: RichTextField;
    Heading: TextField;
    TagLine: TextField;
    Link: LinkField;
  };
  id: string;
}

type TeasersProps = {
  params: { [key: string]: string };
  fields: {
    Heading: TextField;
    Text: TextField;
    Items: Teaser[];
  };
};

const TeaserDefaultComponent = (props: TeasersProps): JSX.Element => (
  <div className={`fetaure-page ${props.params.styles}`}>
    <div className="container">
      <div className="row">
        <span className="is-empty-hint">Teasers</span>
      </div>
    </div>
  </div>
);

export const Default = (props: TeasersProps): JSX.Element => {
  if (props.fields) {
    return (
      <div className={`fetaure-page ${props.params.styles}`}>
        <div className="container">
          <div className="row">
            {props.fields.Items.map((t: Teaser) => {
              return (
                <div className="col-lg-3 col-md-6" key={t.id}>
                  <div className="about-block-item mb-5 mb-lg-0">
                    <NextImage field={t.fields.Image} className="img-fluid w-100"></NextImage>
                    <Text field={t.fields.Heading} tag="h4" className="mt-3"></Text>
                    <RichText field={t.fields.Text} tag="p"></RichText>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </div>
    );
  }

  return <TeaserDefaultComponent {...props} />;
};

export const DoctorsAchievements = (props: TeasersProps): JSX.Element => {
  if (props.fields) {
    return (
      <div className="section awards">
        <div className="container">
          <div className="row align-items-center">
            <div className="col-lg-4">
              <Text field={props.fields.Heading} tag="h2" className="title-color"></Text>
              <div className="divider mt-4 mb-5 mb-lg-0"></div>
            </div>
            <div className="col-lg-8">
              <div className="row">
                {props.fields.Items.map((t: Teaser) => {
                  return (
                    <div className="col-lg-4 col-md-6 col-sm-6" key={t.id}>
                      <div className="award-img">
                        <NextImage field={t.fields.Image} className="img-fluid"></NextImage>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  }

  return <TeaserDefaultComponent {...props} />;
};

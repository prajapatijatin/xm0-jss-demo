import { Field, withDatasourceCheck } from '@sitecore-jss/sitecore-jss-nextjs';
import { ComponentProps } from 'lib/component-props';
import { useI18n } from 'next-localization';

type HeaderTopBarProps = ComponentProps & {
  fields: {
    Email: Field<string>;
    Address: Field<string>;
    PhoneNumber: Field<string>;
  };
};

const HeaderTopBar = ({ fields, rendering }: HeaderTopBarProps): JSX.Element => {
  const { t } = useI18n();
  if (rendering) {
    return (
      <div className="header-top-bar">
        <div className="container">
          <div className="row align-items-center">
            <div className="col-lg-6">
              <ul className="top-bar-info list-inline-item pl-0 mb-0">
                <li className="list-inline-item">
                  <a href={`mailto:${fields.Email.value}`}>
                    <i className="icofont-support-faq mr-2"></i>
                    {fields.Email.value}
                  </a>
                </li>
                <li className="list-inline-item">
                  <i className="icofont-location-pin mr-2"></i>
                  {t('novena-address')} {fields.Address.value}
                </li>
              </ul>
            </div>
            <div className="col-lg-6">
              <div className="text-lg-right top-right-bar mt-2 mt-lg-0">
                <a href="tel:+23-345-67890">
                  <span>{t('novena-call-now')} </span>
                  <span className="h4">{fields.PhoneNumber.value}</span>
                </a>
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  } else {
    return <span>No rendering found.</span>;
  }
};

export default withDatasourceCheck()<HeaderTopBarProps>(HeaderTopBar);

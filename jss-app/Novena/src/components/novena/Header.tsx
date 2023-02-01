import { Placeholder, useSitecoreContext } from '@sitecore-jss/sitecore-jss-nextjs';
import { ComponentProps } from 'lib/component-props';
import { classNames } from 'src/Helpers/Helpers';

type HeaderProps = ComponentProps;

const Header = ({ rendering }: HeaderProps): JSX.Element => {
  const { sitecoreContext } = useSitecoreContext();
  return (
    <>
      <Placeholder name="novena-headless-header-top" rendering={rendering} />
      <nav className="navbar navbar-expand-lg navigation" id="navbar">
        <div className={classNames('container', sitecoreContext.pageEditing ? '' : '')}>
          <Placeholder name="novena-jss-header-bottom" rendering={rendering} />
        </div>
      </nav>
    </>
  );
};

export default Header;

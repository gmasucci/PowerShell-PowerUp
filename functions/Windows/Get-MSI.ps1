<#
$Metadata = @{
	Title = "Get MSI"
	Filename = "Get-MSI.ps1"
	Description = ""
	Tags = "powershell, msi, get"
	Project = ""
	Author = "Janik von Rotz"
	AuthorContact = "http://janikvonrotz.ch"
	CreateDate = "2014-02-24"
	LastEditDate = "2014-02-24"
	Url = ""
	Version = "0.0.0"
	License = @'
This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Switzerland License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/ch/ or 
send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
'@
}
#>

function Get-MSI{

<#
.SYNOPSIS
    Get list of installed MSI packages.

.DESCRIPTION
	Get list of installed MSI packages.

.EXAMPLE 

    Get list of installed MSI packages.
	
    PS C:\> Get-MSI

    ProductCode    : {B199808C-D55F-48A2-AEDC-6C5660D18A23}
    ProductName    : PowerShell Community Extensions 3.0
    LocalPackage   : C:\Windows\Installer\1828a9f.msi
    ProductVersion : 3.0.4.0
    InstallDate    : 13.09.2013 00:00:00

    ProductCode    : {64A5D39C-95CD-4B8B-B2FA-6C713133B57F}
    ProductName    : Microsoft-System-CLR-Typen für SQL Server 2012 (x64)
    LocalPackage   : C:\Windows\Installer\cabef.msi
    ProductVersion : 11.0.2100.60
    InstallDate    : 07.01.2013 00:00:00

.EXAMPLE 
    
    Uninstall a MSI package installation
    
	PS C:\> Get-MSI | where{$_.ProductName -match "SharePoint Client Components"} | msiexec "/uninstall $($_.LocalPackage) /qn
    
.EXAMPLE 

    Uninstall a mulpile MSI installationa silently and wait until the deinstallation has finished.
    
    PS C:\> Get-MSI | where{$_.ProductName -match "SharePoint Client Components"} | ForEach-Object{Start-Process -FilePath "msiexec" -ArgumentList "/uninstall $($_.LocalPackage) /qn" -Wait}
#>

$msiUtilSignature = @'
/// <summary>
/// The HRESULT error code for success.
/// </summary>
private const int ErrorSuccess = 0;
 
/// <summary>
/// The HRESULT error code that indicates there is more
/// data available to retrieve.
/// </summary>
private const int ErrorMoreData = 234;
 
/// <summary>
/// The HRESULT error code that indicates there is
/// no more data available.
/// </summary>
private const int ErrorNoMoreItems = 259;
 
/// <summary>
/// The expected length of a GUID.
/// </summary>
private const int GuidLength = 39;
 
/// <summary>
/// Gets an array of the installed MSI products.
/// </summary>
public Product[] Products
{
    get { return new ProductEnumeratorWrapper(default(Product)).ToArray(); }
}
 
/**
 * http://msdn.microsoft.com/en-us/library/aa370101(VS.85).aspx
 */
 
[DllImport(@"msi.dll", CharSet = CharSet.Auto)]
[return: MarshalAs(UnmanagedType.U4)]
private static extern int MsiEnumProducts(
    [MarshalAs(UnmanagedType.U4)] int iProductIndex,
    [Out] StringBuilder lpProductBuf);
 
/**
 * http://msdn.microsoft.com/en-us/library/aa370130(VS.85).aspx
 */
 
[DllImport(@"msi.dll", CharSet = CharSet.Auto)]
[return: MarshalAs(UnmanagedType.U4)]
private static extern int MsiGetProductInfo(
    string szProduct,
    string szProperty,
    [Out] StringBuilder lpValueBuf,
    [MarshalAs(UnmanagedType.U4)] [In] [Out] ref int pcchValueBuf);
 
#region Nested type: Product
 
/// <summary>
/// An MSI product.
/// </summary>
public struct Product
{
    /// <summary>
    /// Gets or sets the product's unique GUID.
    /// </summary>
    public string ProductCode { get; internal set; }
 
    /// <summary>
    /// Gets the product's name.
    /// </summary>
    public string ProductName { get; internal set; }
 
    /// <summary>
    /// Gets the path to the product's local package.
    /// </summary>
    public FileInfo LocalPackage { get; internal set; }
 
    /// <summary>
    /// Gets the product's version.
    /// </summary>
    public string ProductVersion { get; internal set; }
 
    /// <summary>
    /// Gets the product's install date.
    /// </summary>
    public DateTime InstallDate { get; internal set; }
}
 
#endregion
 
#region Nested type: ProductEnumeratorWrapper
 
private class ProductEnumeratorWrapper : IEnumerable<Product>
{
    private Product data;
 
    public ProductEnumeratorWrapper(Product data)
    {
        this.data = data;
    }
 
    #region IEnumerable<Product> Members
 
    public IEnumerator<Product> GetEnumerator()
    {
        return new ProductEnumerator(this);
    }
 
    IEnumerator IEnumerable.GetEnumerator()
    {
        return GetEnumerator();
    }
 
    #endregion
 
    #region Nested type: ProductEnumerator
 
    private class ProductEnumerator : IEnumerator<Product>
    {
        /// <summary>
        /// A format provider used to format DateTime objects.
        /// </summary>
        private static readonly IFormatProvider DateTimeFormatProvider =
            CultureInfo.CreateSpecificCulture("en-US");
 
        /// <summary>
        /// The enumerator's wrapper.
        /// </summary>
        private readonly ProductEnumeratorWrapper wrapper;
 
        /// <summary>
        /// The index.
        /// </summary>
        private int i;
 
        public ProductEnumerator(ProductEnumeratorWrapper wrapper)
        {
            this.wrapper = wrapper;
        }
 
        #region IEnumerator<Product> Members
 
        public Product Current
        {
            get { return this.wrapper.data; }
        }
 
        object IEnumerator.Current
        {
            get { return this.wrapper.data; }
        }
 
        public bool MoveNext()
        {
            var buffer = new StringBuilder(GuidLength);
            var hresult = MsiEnumProducts(this.i++, buffer);
            this.wrapper.data.ProductCode = buffer.ToString();
 
            switch (hresult)
            {
                case ErrorSuccess:
                {
                    try
                    {
                        this.wrapper.data.InstallDate =
                            DateTime.ParseExact(
                                GetProperty(@"InstallDate"),
                                "yyyyMMdd",
                                DateTimeFormatProvider);
                    }
                    catch 
                    {
                        this.wrapper.data.InstallDate = DateTime.MinValue;
                    }
                     
 
                    try
                    {
                        this.wrapper.data.LocalPackage =
                            new FileInfo(GetProperty(@"LocalPackage"));
                    }
                    catch 
                    {
                        this.wrapper.data.LocalPackage = null;
                    }
                     
                    try
                    {
                        this.wrapper.data.ProductName =
                            GetProperty(@"InstalledProductName");
                    }
                    catch 
                    {
                        this.wrapper.data.ProductName = null;
                    }
                     
                    try
                    {
                        this.wrapper.data.ProductVersion =
                            GetProperty(@"VersionString");
                    }
                    catch
                    {
                        this.wrapper.data.ProductVersion = null;
                    }
 
                    return true;
                }
                case ErrorNoMoreItems:
                {
                    return false;
                }
                default:
                {
                    // throw new Win32Exception(hresult);
                    return true;
                }
            }
        }
 
        public void Reset()
        {
            this.i = 0;
        }
 
        public void Dispose()
        {
            // Do nothing
        }
 
        #endregion
 
        /// <summary>
        /// Gets an MSI property.
        /// </summary>
        /// <param name="name">The name of the property to get.</param>
        /// <returns>The property's value.</returns>
        /// <remarks>
        /// For more information on available properties please see:
        /// http://msdn.microsoft.com/en-us/library/aa370130(VS.85).aspx
        /// </remarks>
        private string GetProperty(string name)
        {
            var size = 0;
            var hresult =
                MsiGetProductInfo(
                    this.wrapper.data.ProductCode, name, null, ref size);
 
            if (hresult == ErrorSuccess || hresult == ErrorMoreData)
            {
                var buffer = new StringBuilder(++size);
                hresult =
                    MsiGetProductInfo(
                        this.wrapper.data.ProductCode,
                        name,
                        buffer,
                        ref size);
 
                if (hresult == ErrorSuccess)
                {
                    return buffer.ToString();
                }
            }
 
            throw new Win32Exception(hresult);
        }
    }
 
    #endregion
}
 
#endregion
'@;
     
    $msiUtilType = Add-Type `
        -MemberDefinition $msiUtilSignature `
        -Name "MsiUtil" `
        -Namespace "Win32Native" `
        -Language CSharpVersion3 `
        -UsingNamespace System.Linq, `
                        System.IO, `
                        System.Collections, `
                        System.Collections.Generic, `
                        System.ComponentModel, `
                        System.Globalization, `
                        System.Text `
        -PassThru;
     
    # Initialize a new Win32Native.MsiUtil object.
    $msiUtil = New-Object -TypeName "Win32Native.MsiUtil";
     
    # Print the pubished or installed products.
    $msiUtil.Products
}
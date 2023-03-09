// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "../ERC/IERC20.sol";

contract Project {
    event OwnerChangedEvent(address caller, address newOwner);
    event ProjectFeeChangedEvent(
        address caller,
        address feeToken,
        uint feeAmount
    );

    address owner;

    uint public fee; // 交易手续费，为固定值
    address public feeToken; // 交易手续费收取的代币

    constructor() {
        owner = msg.sender;
    }

    // 通缩费率
    mapping(address => uint) public deflationContract;
    mapping(address => uint) public deflationUser;

    mapping(address => bool) public isProjectInit; // addresss[0] 项目coin地址
    // 其他信息
    mapping(address => address) public project; // addresss[0] 项目coin地址
    mapping(address => address) public projectOwner; // addresss[1] 项目方钱包
    mapping(address => uint) public projectAmount; // uints[0] 配置-项目coin总额

    mapping(address => uint) public startTime; //uints[1] 活动开始时间
    mapping(address => uint) public endTime; //uints[2] 活动结束时间
    mapping(address => uint) public freeLineTime; // uints[3] 线性释放时间戳

    // 基础配置
    mapping(address => address) public invest; // addresss[2] 投资coin地址
    mapping(address => uint) public investBuyMax; // uints[4] 投资最大额
    mapping(address => uint) public investBuyMin; // uints[5] 投资最小额
    mapping(address => uint) public investAmount; // uints[6] 投资coin总额
    // 算法结果
    mapping(address => uint) public investToOwner; // 运算-参与项目总coin
    mapping(address => uint) public projectPoolTotal; // 运算-FIST池子总额
    mapping(address => uint) public ratio; // 代币转换利率，100000意为100%

    function initProjectInfo(
        address[] memory addresss,
        uint[] memory uints
    ) external {
        require(isProjectInit[addresss[0]] == false, "project init");

        bool isSendFee = true;
        address projectAddress = addresss[0];
        uint amount = uints[0];

        bool isAddTokenOutSuccess = IERC20(projectAddress).transferFrom(
            msg.sender,
            address(this),
            amount
        );

        if (fee != 0) {
            isSendFee = IERC20(feeToken).transferFrom(msg.sender, owner, fee);
        }

        calculDeflationRatio(projectAddress);

        if (deflationContract[projectAddress] != 0) {
            amount = uint(
                (amount * (10 ** 18 - deflationContract[projectAddress])) /
                    (10 ** 18)
            );
        }

        if (isAddTokenOutSuccess && isSendFee) {
            projectPoolTotal[projectAddress] =
                amount -
                (1000 *
                    (deflationContract[projectAddress] +
                        deflationUser[projectAddress])) /
                10 ** 18 -
                2; // 初始化池子总量
            _projectBaseConfig(projectAddress, addresss, uints);
        }
    }

    function _projectBaseConfig(
        address projectAddress,
        address[] memory addresss,
        uint[] memory uints
    ) internal {
        /* address */
        project[projectAddress] = addresss[0];
        projectOwner[projectAddress] = addresss[1];
        invest[projectAddress] = addresss[2];
        /* uint */
        projectAmount[projectAddress] = uints[0];
        startTime[projectAddress] = uints[1];
        endTime[projectAddress] = uints[2];
        freeLineTime[projectAddress] = uints[3];
        investBuyMax[projectAddress] = uints[4];
        investBuyMin[projectAddress] = uints[5];
        investAmount[projectAddress] = uints[6];
        isProjectInit[projectAddress] = true;
        ratio[projectAddress] = uint((uints[0] * 10 ** 18) / uints[6]);

        // 如果是通缩货币
        if (deflationContract[projectAddress] != 0) {
            investAmount[projectAddress] =
                (uints[6] * (10 ** 18 - deflationContract[projectAddress])) /
                (10 ** 18);
            ratio[projectAddress] = uint(
                (projectPoolTotal[projectAddress] * 10 ** 18) / uints[6]
            );
        }

        require(ratio[projectAddress] != 0);
    }

    function calculDeflationRatio(address token) internal {
        IERC20 Token = IERC20(token);

        // transferFrom通缩
        uint calContractBefore = Token.balanceOf(address(this));
        Token.approve(address(this), 1000);
        Token.transferFrom(address(this), address(this), 1000);
        uint calContractAfter = Token.balanceOf(address(this));
        deflationContract[token] =
            ((calContractBefore - calContractAfter) * 10 ** 18) /
            1000;

        // transfert通缩
        uint calUserBefore = Token.balanceOf(address(this));
        Token.transfer(address(this), 1000);
        uint calUserAfter = Token.balanceOf(address(this));
        deflationUser[token] =
            ((calUserBefore - calUserAfter) * 10 ** 18) /
            1000;
    }

    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
        emit OwnerChangedEvent(msg.sender, _owner);
    }

    function setFee(uint _feeAmount, address _feeToken) external onlyOwner {
        fee = _feeAmount;
        feeToken = _feeToken;
        emit ProjectFeeChangedEvent(msg.sender, _feeToken, _feeAmount);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    modifier onlyProjectOwner(address _project) {
        address _owner = projectOwner[_project];
        require(_owner == msg.sender, "not owner");
        _;
    }
}
